import boto3
import time
import random
import string
import sys
from botocore.exceptions import ClientError

# Configuration
REGION = "us-east-1"
YOUR_NAME = "justo"
PROJECT = "capstone"

ec2 = boto3.client('ec2', region_name=REGION)
elbv2 = boto3.client('elbv2', region_name=REGION)
s3 = boto3.client('s3', region_name=REGION)

def get_random_string(length=6):
    return ''.join(random.choices(string.ascii_lowercase + string.digits, k=length))

def get_vpc_by_name(name):
    vpcs = ec2.describe_vpcs(Filters=[{'Name': 'tag:Name', 'Values': [name]}])['Vpcs']
    return vpcs[0]['VpcId'] if vpcs else None

def wait_for_nat_gw(nat_gw_id):
    print(f"⌛ Waiting for NAT Gateway {nat_gw_id} to be available...")
    waiter = ec2.get_waiter('nat_gateway_available')
    waiter.wait(NatGatewayIds=[nat_gw_id])
    print(f"✅ NAT Gateway {nat_gw_id} is ready.")

def wait_for_alb(alb_arn):
    print(f"⌛ Waiting for ALB to be ACTIVE (this takes ~3 mins)...")
    waiter = elbv2.get_waiter('load_balancer_available')
    waiter.wait(LoadBalancerArns=[alb_arn])
    print(f"✅ ALB is ACTIVE.")

def create_tags(resource_id, name, env):
    ec2.create_tags(
        Resources=[resource_id],
        Tags=[
            {'Key': 'Name', 'Value': name},
            {'Key': 'Environment', 'Value': env},
            {'Key': 'Project', 'Value': PROJECT}
        ]
    )

def setup_environment(env, vpc_cidr, pub_a_cidr, pub_b_cidr, priv_a_cidr, priv_b_cidr):
    print(f"\n🚀 --- Building {env.upper()} Environment ---")
    
    try:
        # 1. VPC
        vpc_name = f"{env}-vpc"
        vpc_id = get_vpc_by_name(vpc_name)
        if not vpc_id:
            vpc = ec2.create_vpc(CidrBlock=vpc_cidr)
            vpc_id = vpc['Vpc']['VpcId']
            ec2.modify_vpc_attribute(VpcId=vpc_id, EnableDnsSupport={'Value': True})
            ec2.modify_vpc_attribute(VpcId=vpc_id, EnableDnsHostnames={'Value': True})
            create_tags(vpc_id, vpc_name, env)
            print(f"✅ Created VPC: {vpc_id}")
        else:
            print(f"⏩ VPC {vpc_id} already exists.")

        # 2. Internet Gateway
        igws = ec2.describe_internet_gateways(Filters=[{'Name': 'attachment.vpc-id', 'Values': [vpc_id]}])['InternetGateways']
        if not igws:
            igw = ec2.create_internet_gateway()
            igw_id = igw['InternetGateway']['InternetGatewayId']
            ec2.attach_internet_gateway(InternetGatewayId=igw_id, VpcId=vpc_id)
            create_tags(igw_id, f"{env}-igw", env)
            print(f"✅ Created IGW: {igw_id}")
        else:
            igw_id = igws[0]['InternetGatewayId']
            print(f"⏩ IGW {igw_id} exists.")

        # 3. Subnets
        def get_or_create_sub(cidr, az, name):
            subs = ec2.describe_subnets(Filters=[{'Name': 'vpc-id', 'Values': [vpc_id]}, {'Name': 'cidr-block', 'Values': [cidr]}])['Subnets']
            if subs:
                print(f"⏩ Subnet {name} ({cidr}) exists.")
                return subs[0]['SubnetId']
            s = ec2.create_subnet(VpcId=vpc_id, CidrBlock=cidr, AvailabilityZone=az)['Subnet']['SubnetId']
            create_tags(s, name, env)
            print(f"✅ Created Subnet: {name}")
            return s

        sub_pub_a = get_or_create_sub(pub_a_cidr, f"{REGION}a", f"{env}-public-subnet-a")
        sub_pub_b = get_or_create_sub(pub_b_cidr, f"{REGION}b", f"{env}-public-subnet-b")
        sub_priv_a = get_or_create_sub(priv_a_cidr, f"{REGION}a", f"{env}-private-subnet-a")
        sub_priv_b = get_or_create_sub(priv_b_cidr, f"{REGION}b", f"{env}-private-subnet-b")

        # 4. NAT Gateway
        nats = ec2.describe_nat_gateways(Filters=[{'Name': 'vpc-id', 'Values': [vpc_id]}, {'Name': 'state', 'Values': ['pending', 'available']}])['NatGateways']
        if not nats:
            eip_nat = ec2.allocate_address(Domain='vpc')['AllocationId']
            nat_gw = ec2.create_nat_gateway(SubnetId=sub_pub_a, AllocationId=eip_nat)
            nat_gw_id = nat_gw['NatGateway']['NatGatewayId']
            create_tags(nat_gw_id, f"{env}-nat-gw", env)
            wait_for_nat_gw(nat_gw_id)
        else:
            nat_gw_id = nats[0]['NatGatewayId']
            print(f"⏩ NAT Gateway {nat_gw_id} exists.")

        # 5. Route Tables
        def get_or_create_rt(name, target_id, is_igw=True):
            rts = ec2.describe_route_tables(Filters=[{'Name': 'vpc-id', 'Values': [vpc_id]}, {'Name': 'tag:Name', 'Values': [name]}])['RouteTables']
            if rts:
                print(f"⏩ Route Table {name} exists.")
                return rts[0]['RouteTableId']
            rt = ec2.create_route_table(VpcId=vpc_id)['RouteTable']['RouteTableId']
            if is_igw:
                ec2.create_route(RouteTableId=rt, DestinationCidrBlock='0.0.0.0/0', GatewayId=target_id)
            else:
                ec2.create_route(RouteTableId=rt, DestinationCidrBlock='0.0.0.0/0', NatGatewayId=target_id)
            create_tags(rt, name, env)
            print(f"✅ Created RT: {name}")
            return rt

        rt_pub = get_or_create_rt(f"{env}-public-rt", igw_id, True)
        ec2.associate_route_table(RouteTableId=rt_pub, SubnetId=sub_pub_a)
        ec2.associate_route_table(RouteTableId=rt_pub, SubnetId=sub_pub_b)

        rt_priv = get_or_create_rt(f"{env}-private-rt", nat_gw_id, False)
        ec2.associate_route_table(RouteTableId=rt_priv, SubnetId=sub_priv_a)
        ec2.associate_route_table(RouteTableId=rt_priv, SubnetId=sub_priv_b)

        # 6. Security Groups
        def get_or_create_sg(name, desc):
            sgs = ec2.describe_security_groups(Filters=[{'Name': 'vpc-id', 'Values': [vpc_id]}, {'Name': 'group-name', 'Values': [name]}])['SecurityGroups']
            if sgs:
                print(f"⏩ Security Group {name} exists.")
                return sgs[0]['GroupId']
            sg = ec2.create_security_group(GroupName=name, Description=desc, VpcId=vpc_id)['GroupId']
            create_tags(sg, name, env)
            print(f"✅ Created SG: {name}")
            return sg

        alb_sg = get_or_create_sg(f"capstone-{env}-alb-sg", f"ALB SG for {env}")
        try:
            ec2.authorize_security_group_ingress(GroupId=alb_sg, IpProtocol='tcp', FromPort=80, ToPort=80, CidrIp='0.0.0.0/0')
        except ClientError: pass

        ec2_sg = get_or_create_sg(f"capstone-{env}-ec2-sg", f"EC2 SG for {env}")
        try:
            ec2.authorize_security_group_ingress(
                GroupId=ec2_sg,
                IpPermissions=[
                    {'IpProtocol': 'tcp', 'FromPort': 80, 'ToPort': 80, 'UserIdGroupPairs': [{'GroupId': alb_sg}]},
                    {'IpProtocol': 'tcp', 'FromPort': 22, 'ToPort': 22, 'IpRanges': [{'CidrIp': '10.0.0.0/8'}]}
                ]
            )
        except ClientError: pass

        # 7. EC2 Instance
        insts = ec2.describe_instances(Filters=[{'Name': 'vpc-id', 'Values': [vpc_id]}, {'Name': 'tag:Name', 'Values': [f"web-{env}"]}, {'Name': 'instance-state-name', 'Values': ['running', 'pending']}])['Reservations']
        if not insts:
            user_data = f"""#!/bin/bash
yum update -y; yum install -y httpd
echo "<h1>Capstone {env.upper()} Server - $(hostname -f)</h1>" > /var/www/html/index.html
systemctl start httpd; systemctl enable httpd
"""
            instance_id = ec2.run_instances(ImageId='ami-0c02fb55956c7d316', InstanceType='t3.micro', MinCount=1, MaxCount=1, SubnetId=sub_priv_a, SecurityGroupIds=[ec2_sg], UserData=user_data)['Instances'][0]['InstanceId']
            create_tags(instance_id, f"web-{env}", env)
            print(f"✅ Created EC2: {instance_id}")
        else:
            instance_id = insts[0]['Instances'][0]['InstanceId']
            print(f"⏩ EC2 Instance {instance_id} exists.")

        # 8. ALB
        alb_name = f"capstone-{env}-alb"
        try:
            alb_arn = elbv2.describe_load_balancers(Names=[alb_name])['LoadBalancers'][0]['LoadBalancerArn']
            print(f"⏩ ALB {alb_name} exists.")
        except elbv2.exceptions.LoadBalancerNotFoundException:
            print("⌛ Creating ALB...")
            alb_arn = elbv2.create_load_balancer(Name=alb_name, Subnets=[sub_pub_a, sub_pub_b], SecurityGroups=[alb_sg], Scheme='internet-facing', Type='application')['LoadBalancers'][0]['LoadBalancerArn']
            tg_arn = elbv2.create_target_group(Name=f"capstone-{env}-ec2-tg", Protocol='HTTP', Port=80, VpcId=vpc_id, TargetType='instance')['TargetGroups'][0]['TargetGroupArn']
            elbv2.register_targets(TargetGroupArn=tg_arn, Targets=[{'Id': instance_id}])
            elbv2.create_listener(LoadBalancerArn=alb_arn, Protocol='HTTP', Port=80, DefaultActions=[{'Type': 'forward', 'TargetGroupArn': tg_arn}])
            print(f"✅ Created ALB: {alb_arn}")

        # 9. NLB (Wait for ALB ACTIVE first!)
        nlb_name = f"capstone-{env}-nlb"
        try:
            nlb_arn = elbv2.describe_load_balancers(Names=[nlb_name])['LoadBalancers'][0]['LoadBalancerArn']
            print(f"⏩ NLB {nlb_name} exists.")
        except elbv2.exceptions.LoadBalancerNotFoundException:
            wait_for_alb(alb_arn) # BLOCKING WAIT
            print("⌛ Creating NLB...")
            eip_nlb = ec2.allocate_address(Domain='vpc')['AllocationId']
            nlb_arn = elbv2.create_load_balancer(Name=nlb_name, SubnetMappings=[{'SubnetId': sub_pub_a, 'AllocationId': eip_nlb}], Type='network', Scheme='internet-facing')['LoadBalancers'][0]['LoadBalancerArn']
            tg_alb_arn = elbv2.create_target_group(Name=f"capstone-{env}-alb-tg", Protocol='TCP', Port=80, VpcId=vpc_id, TargetType='alb')['TargetGroups'][0]['TargetGroupArn']
            elbv2.register_targets(TargetGroupArn=tg_alb_arn, Targets=[{'Id': alb_arn}])
            elbv2.create_listener(LoadBalancerArn=nlb_arn, Protocol='TCP', Port=80, DefaultActions=[{'Type': 'forward', 'TargetGroupArn': tg_alb_arn}])
            print(f"✅ Created NLB: {nlb_arn}")

    except ClientError as e:
        print(f"❌ ERROR: {e}"); sys.exit(1)

def create_s3_bucket(name):
    full_name_base = f"{name}-{YOUR_NAME}-"
    buckets = s3.list_buckets()['Buckets']
    exists = [b['Name'] for b in buckets if b['Name'].startswith(full_name_base)]
    if exists:
        print(f"⏩ Bucket {exists[0]} exists."); return
    full_name = f"{full_name_base}{get_random_string()}"
    try:
        s3.create_bucket(Bucket=full_name)
        s3.put_bucket_encryption(Bucket=full_name, ServerSideEncryptionConfiguration={'Rules': [{'ApplyServerSideEncryptionByDefault': {'SSEAlgorithm': 'AES256'}}]})
        s3.put_public_access_block(Bucket=full_name, PublicAccessBlockConfiguration={'BlockPublicAcls': True, 'IgnorePublicAcls': True, 'BlockPublicPolicy': True, 'RestrictPublicBuckets': True})
        s3.put_bucket_versioning(Bucket=full_name, VersioningConfiguration={'Status': 'Enabled'})
        print(f"✅ Created S3: {full_name}")
    except ClientError as e: print(f"❌ S3 ERROR: {e}")

if __name__ == "__main__":
    setup_environment("dev", "10.0.0.0/16", "10.0.1.0/24", "10.0.3.0/24", "10.0.2.0/24", "10.0.4.0/24")
    setup_environment("prod", "10.1.0.0/16", "10.1.1.0/24", "10.1.3.0/24", "10.1.2.0/24", "10.1.4.0/24")
    print("\n📦 --- Building Storage ---")
    create_s3_bucket("capstone-dev")
    create_s3_bucket("capstone-prod")
    create_s3_bucket("capstone-tfstate")
    print("\n🎉 ALL RESOURCES CREATED SUCCESSFULLY!")
