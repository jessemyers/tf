# ses_domain

Creates an SES email domain and configure notification to SNS.

The provided domain name is assumed to be managed in Route53.

Note that manual work will be required to request approval to exit the SES sandbox for sending
mail to external domains. A description of the use cases of this system and how it handles
complaints and bounces will help expedite that such a request. Email addresses may also be added
manually (but not via Terraform) for testing to specific addresses.

 -
