
  <h3 align="center">Terraform AWS Web Server</h3>

  <p align="center">
    Using Terraform for web-server creation via AWS EC2 instance with Vault for secret injection
    
  </p>
</p>


## Prerequisites

- AWS Free tier account
- Basic Linux Knowledge
- Port/Network knowledge (80,443,22) SSH
- Basic Terraform commands
- Patience

## How to recreate

Steps

- 1 ) [This is the inital tutorial to follow to create your EC2 instance via Terraform](https://www.youtube.com/watch?v=SLB_c_ayRMo). The tutorial is about 2 years old so there are some changes within Terraform but the documentation is up to date on the Hashicorp site.  Following this will get an individual up-to-speed with IaC use but by using hard-coded credentials within the code. Once you are able to create the EC2 instance, you can move onto integrating Hashicorp Vault for secrets. <br> <br> 


> --There are some small things you might have to trouble shoot in the tutorial.  <br>
> --Keep notice of the AMI for each flavor of EC2 instance. Some commands listed are not native to each flavor of linux. I found that 'sudo apt' works with the Ubuntu image I used. Others may need to use Yum.
> <br> -- Also I realized that browsers we use today mostly deafult to HTTPS when opening links. When attempting to access your EC2 instance via public IP .... COPY THE IP ADDRESS and manually add "http://". You'll save yourself some time figuring out why you can't access your EC2 instance.  
- 2 ) Once you have your terraform file and apache web-server fucntioning we can use a [Hashicorp Vault Tutorial for secret injection](https://developer.hashicorp.com/terraform/tutorials/secrets/secrets-vault). Following this allows you to store your long-lived AWS credentials in HashiCorp's Vault's AWS Secrets Engine, then leverage Terraform's Vault provider to generate appropriately scoped & short-lived AWS credentials to be used by Terraform to provision resources in AWS. [Github repo](https://github.com/hashicorp/learn-terraform-inject-secrets-aws-vault)
- 3 ) In the Hashicorp repo. There is a code specifying the EC2 type creation <br>
```
data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-trusty-14.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

# Create AWS EC2 Instance
resource "aws_instance" "main" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t2.nano"

  tags = {
    Name  = var.name
    TTL   = var.ttl
    owner = "${var.name}-guide"
  }
```
What you as a user need to do is simply replace this block of code with your Terraform file from the previous tutorial and follow the steps.  You'll be working in two different directories assuming both roles of the "Vault Admin" and "Terraform Operator" 

<br>

## In this repo, I've attached my .tf file so you may reference if needed. 

```
       \:.             .:/
        \``._________.''/ 
         \             / 
 .--.--, / .':.   .':. \
/__:  /  | '::' . '::' |
   / /   |`.   ._.   .'|
  / /    |.'         '.|
 /___-_-,|.\  \   /  /.|
      // |''\.;   ;,/ '|
      `==|:=         =:|
         `.          .'
           :-._____.-:
          `''       `''      GOOD LUCK and DONT FORGET TO DESTROY YOUR RESOURCES 
```
