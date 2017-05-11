require 'yaml'

api_settings = YAML.load_file(File.join(Rails.root, 'config', 'apis.yml'))

AWS_S3 = Aws::S3::Resource.new(credentials: Aws::Credentials.new(
                                   api_settings['aws_akid'],
                                   api_settings['aws_secret']
                               ), region: 'us-west-1')

SHOPNAME = api_settings['shopname']
SHOP_URL = "https://#{api_settings['shopify_api_key']}:#{api_settings['password']}@#{api_settings['shopname']}.myshopify.com/admin"