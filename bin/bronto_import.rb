require 'csv'
require 'faraday'
require 'json'

API_KEY = ''
PASSWORD = ''
HOSTNAME = ''
BASE_URL = "https://#{API_KEY}:#{PASSWORD}@#{HOSTNAME}"
FILENAME = "#{Date.today.to_s}_import.csv"

def cart_count(params=nil)
  conn = Faraday.new(url: BASE_URL, ssl: { verify: false }) do |faraday|
    faraday.request  :url_encoded             # form-encode POST params
    faraday.adapter  Faraday.default_adapter  # make requests with Net::https
  end

  response = conn.get do |req|
    req.url '/admin/checkouts/count.json'
    req.params = {created_at_min: params[:created_at_min], created_at_max: params[:created_at_max]} if !params.nil?
  end
  JSON.parse(response.body)["count"]
end

def cart_product_info(product_id)
  conn = Faraday.new(url: BASE_URL, ssl: { verify: false }) do |faraday|
    faraday.request  :url_encoded             # form-encode POST params
    faraday.adapter  Faraday.default_adapter  # make requests with Net::https
  end

  response = conn.get do |req|
    req.url "/admin/products/#{product_id}.json"
  end
  JSON.parse(response.body)["product"]
end

def max_time(time_current)
  (time_current - time_current.sec - time_current.min%30*60)
end

def min_time(time_current)
  max_time(time_current - 30*60)
end

def abandoned_carts(time_current=nil)
  conn = Faraday.new(url: BASE_URL, ssl: { verify: false }) do |faraday|
    faraday.request  :url_encoded             # form-encode POST params
    faraday.adapter  Faraday.default_adapter  # make requests with Net::https
  end

  params = time_current.nil? ? nil : {created_at_min: min_time(time_current).to_s, created_at_max: max_time(time_current).to_s}
  count = cart_count(params)
  puts "GRABBING: #{count} abandoned carts. hold steady..."
  resp = []
  page = 1
  while count > 0
    response = conn.get do |req|
      req.url '/admin/checkouts.json'
      req.params = {
        'limit': 250,
        'page': page
      }.merge!(params)
    end
    resp += JSON.parse(response.body)["checkouts"]
    count -= 250
    page += 1
  end
  resp
end

def to_csv(carts)
  CSV.open(FILENAME, "w") do |csv| #open new file for write
    sample = csv_formatted_cart({})
    csv << sample.keys
    carts.each do |hash| #open json to parse
      csv << csv_formatted_cart(hash).values #write value to file
    end
  end
end

def cart_billing_address(billing_address)
  if billing_address
    {
      billing_address_address1: billing_address["address1"],
      billing_address_address2: billing_address["address2"],
      billing_address_city: billing_address["city"],
      billing_address_company: billing_address["company"],
      billing_address_country: billing_address["country"],
      billing_address_first_name: billing_address["first_name"],
      billing_address_id: billing_address["id"],
      billing_address_last_name: billing_address["last_name"],
      billing_address_phone: billing_address["phone"],
      billing_address_province: billing_address["province"],
      billing_address_zip: billing_address["zip"],
      billing_address_name: billing_address["name"],
      billing_address_province_code: billing_address["province_code"],
      billing_address_country_code: billing_address["country_code"],
     }
  else
    {
      billing_address_address1: "",
      billing_address_address2: "",
      billing_address_city: "",
      billing_address_company: "",
      billing_address_country: "",
      billing_address_first_name: "",
      billing_address_id: "",
      billing_address_last_name: "",
      billing_address_phone: "",
      billing_address_province: "",
      billing_address_zip: "",
      billing_address_name: "",
      billing_address_province_code: "",
      billing_address_country_code: "",
     }
  end
end

def cart_customer(customer)
  if customer
    {
      customer_accepts_marketing: customer["accepts_marketing"],
      customer_created_at: customer["created_at"],
      customer_email: customer["email"],
      customer_first_name: customer["first_name"],
      customer_id: customer["id"],
      customer_last_name: customer["last_name"],
      customer_note: customer["note"],
      customer_orders_count: customer["orders_count"],
      customer_state: customer["state"],
      customer_total_spent: customer["total_spent"],
      customer_updated_at: customer["updated_at"],
      customer_tags: customer["tags"],
     }
  else
    {
      customer_accepts_marketing: "",
      customer_created_at: "",
      customer_email: "",
      customer_first_name: "",
      customer_id: "",
      customer_last_name: "",
      customer_note: "",
      customer_orders_count: "",
      customer_state: "",
      customer_total_spent: "",
      customer_updated_at: "",
      customer_tags: "",
    }
  end
end

def cart_shipping_address(shipping_address)
  if shipping_address
    {
    shipping_address_address1: shipping_address["address1"],
    shipping_address_address2: shipping_address["address2"],
    shipping_address_city: shipping_address["city"],
    shipping_address_company: shipping_address["company"],
    shipping_address_country: shipping_address["country"],
    shipping_address_first_name: shipping_address["first_name"],
    shipping_address_last_name: shipping_address["last_name"],
    shipping_address_latitude: shipping_address["latitude"],
    shipping_address_longitude: shipping_address["longitude"],
    shipping_address_phone: shipping_address["phone"],
    shipping_address_province: shipping_address["province"],
    shipping_address_zip: shipping_address["zip"],
    shipping_address_name: shipping_address["name"],
    shipping_address_country_code: shipping_address["country_code"],
    shipping_address_province_code: shipping_address["province_code"],
   }
  else
    {
      shipping_address_address1: "",
      shipping_address_address2: "",
      shipping_address_city: "",
      shipping_address_company: "",
      shipping_address_country: "",
      shipping_address_first_name: "",
      shipping_address_last_name: "",
      shipping_address_latitude: "",
      shipping_address_longitude: "",
      shipping_address_phone: "",
      shipping_address_province: "",
      shipping_address_zip: "",
      shipping_address_name: "",
      shipping_address_country_code: "",
      shipping_address_province_code: "",
   }
  end
end

def cart_discount(discount_codes)
  if discount_codes.nil? || discount_codes.length == 0
    {discount_code: ""}
  else
    {discount_code: discount_codes[0]["code"]}
  end
end

def cart_line_items(line_items)
  if line_items && line_items.length != 0
    [{lineitem_name: line_items[0]["title"], product_variant: line_items[0]["variant_title"]}, line_items[0]['product_id']]
  else
    [{lineitem_name: "", product_variant: ""}, nil]
  end
end

def cart_product(product)
  if product
    product_info = cart_product_info(product)
    product = {
      product_url: "http://flexfits.com/products/#{product_info['handle']}",
      product_img_url: product_info['images'][0]['src']
    }
  else
    {
      product_url: "",
      product_img_url: "",
      product_color: "",
      product_size: ""
    }
  end
end


def csv_formatted_cart(cart)
  billing_address = cart_billing_address(cart["billing_address"])
  base_level = {
    abandoned_checkout_url: cart["abandoned_checkout_url"],
    buyer_accepts_marketing: cart["buyer_accepts_marketing"],
    cancel_reason: cart["cancel_reason"],
    cart_token: cart["cart_token"],
    closed_at: cart["closed_at"],
    completed_at: cart["completed_at"],
    created_at: cart["created_at"],
    currency: cart["currency"],
    discount_codes: cart["discount_codes"],
    email: cart["email"],
    gateway: cart["gateway"],
    id: cart["id"],
    landing_site: cart["landing_site"],
    note: cart["note"],
    referring_site: cart["referring_site"],
    source_name: cart["source_name"],
    subtotal_price: cart["subtotal_price"],
    taxes_included: cart["taxes_included"],
    token: cart["token"],
    total_discounts: cart["total_discounts"],
    total_line_items_price: cart["total_line_items_price"],
    total_price: cart["total_price"],
    total_tax: cart["total_tax"],
    total_weight: cart["total_weight"],
    updated_at: cart["updated_at"],
   }
  customer = cart_customer(cart["customer"])
  line_items, product_id = cart_line_items(cart["line_items"])
  shipping_address = cart_shipping_address(cart["shipping_address"])
  discount_code = cart_discount(cart["discount_codes"])
  product_info = cart_product(product_id)
  formatted_cart = base_level.merge(billing_address).merge(customer).merge(shipping_address).merge(discount_code).merge(line_items).merge(product_info)
end

def bronto_upload
  conn = Faraday.new(url: "http://app.bronto.com/", ssl: { verify: false }) do |f|
    f.request :multipart
    f.request :url_encoded
    f.adapter :net_http # This is what ended up making it work
  end
  payload = {
    filename: Faraday::UploadIO.new(FILENAME, "csv"), source: "Daily direct import",
    site_id: , user_id: , key: "",
    action: "addupdate_transactional", format: "csv", email: "",
    listname: "Abandoned Cart Shopify List", status: "transactional", preserveTransactional: true,
  }
  response = conn.post '/mail/subscriber_upload/index/', payload
  puts "RESP: #{response.body}"
end

def main
  time_current = Time.new
  puts "Getting hourly carts up to #{max_time(time_current).to_s}."
  response = abandoned_carts(time_current=time_current)
  to_csv(response)
  bronto_upload
  puts "Added #{response.length} email(s) to contacts."
  File.delete(FILENAME)
  puts "CSV deleted. Good day!"
end

# only run when this file is being run.
if __FILE__ == $0
  main
end
