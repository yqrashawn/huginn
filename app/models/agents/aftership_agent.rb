require 'uri'

module Agents
  class AftershipAgent < Agent

    API_URL = 'https://api.aftership.com/v4'

    description <<-MD
      The Aftership agent allows you to track your shipment from aftership and emit them into events.

      To be able to use the Aftership API, you need to generate an `API Key`. You need a paying plan to use their tracking feature.

      You can use this agent to either retrieve or delete data. The keys are `get` and `delete`. You have to provide a specific request and its associated option.
 
      To get all trackings for your packages please enter `get` for key and `/trackings` for the option.
      To get tracking for a specific tracking number, add the extra options `slug`, `tracking_number` and set `single_tracking_request` to true.

      To get all tracking results for backup purpose set key to `get` and option to `/trackings/export`.

      To get the last checkpoint of a package set key to `get` and option to `/last_checkpoint` plus provide `slug` and `tracking_number`

      `slug` is a unique courier code. 
      
      You have two options to get courier information along with `get`, `/couriers` 
      which returns the couriers that are activiated at your account and the other is `/couriers/all` which returns all couriers.

      The `delete` option allows you to delete a specific shipment. It is `/trackings/:slug/:tracking_number`.

      All urls must be properly formatted with a `/` in front.

      Required Options:

      * `Content-Type` application/json
      * `api_key` - YOUR_API_KEY.
      * `get/delete and its associated options`
    MD

    event_description <<-MD
      A typical tracking event has 3 objects (attributes, tracking, and checkpoint) and it looks like this
          {
        "meta": {
            "code": 200
        },
        "data": {
            "page": 1,
            "limit": 100,
            "count": 3,
            "keyword": "",
            "slug": "",
            "origin": [],
            "destination": [],
            "tag": "",
            "fields": "",
            "created_at_min": "2014-03-27T07:36:14+00:00",
            "created_at_max": "2014-06-25T07:36:14+00:00",
            "trackings": [
                {
                    "id": "53aa7b5c415a670000000021",
                    "created_at": "2014-06-25T07:33:48+00:00",
                    "updated_at": "2014-06-25T07:33:55+00:00",
                    "tracking_number": "123456789",
                    "tracking_account_number": null,
                    "tracking_postal_code": null,
                    "tracking_ship_date": null,
                    "slug": "dhl",
                    "active": false,
                    "custom_fields": {
                        "product_price": "USD19.99",
                        "product_name": "iPhone Case"
                    },
                    "customer_name": null,
                    "destination_country_iso3": null,
                    "emails": [
                        "email@yourdomain.com",
                        "another_email@yourdomain.com"
                    ],
                    "expected_delivery": null,
                    "note": null,
                    "order_id": "ID 1234",
                    "order_id_path": "http://www.aftership.com/order_id=1234",
                    "origin_country_iso3": null,
                    "shipment_package_count": 0,
                    "shipment_type": null,
                    "signed_by": "raul",
                    "smses": [],
                    "source": "api",
                    "tag": "Delivered",
                    "title": "Title Name",
                    "tracked_count": 1,
                    "unique_token": "xy_fej9Llg",
                    "checkpoints": [
                        {
                            "slug": "dhl",
                            "city": null,
                            "created_at": "2014-06-25T07:33:53+00:00",
                            "country_name": "VALENCIA - SPAIN",
                            "message": "Awaiting collection by recipient as requested",
                            "country_iso3": null,
                            "tag": "InTransit",
                            "checkpoint_time": "2014-05-12T12:02:00",
                            "coordinates": [],
                            "state": null,
                            "zip": null
                       },
                        ...
                    ]
                },
                ...
            ]
        }
     }
    MD

    def default_options
      { 'api_key' => 'YOUR_API_KEY',
        'Content_Type' => 'application/json',
        'get' => '/trackings'
      }
    end

    def single_tracking_request?
      interpolated[:single_tracking_request] != "false"
    end

    def uri
      uri = URI.parse API_URL
      if single_tracking_request?
        uri.query = interpolated['get']+ '/' + interpolated['slug'] + '/' + interpolated['tracking_number'] if uri.query.nil? 
      else
        uri.query = interpolated['get'] if uri.query.nil? 
      end
      uri.to_s.gsub('?','') 
    end

    def working?
      true
    end

    def validate_options
      errors.add(:base, "You need to specify a api key") unless options['api_key'].present?
      errors.add(:base, "Content-Type must be set to application/json") unless options['Content_Type'].present? && options['Content_Type'] == 'application/json'
    end

    def request_options
      {:headers => {"aftership-api-key" => interpolated['api_key'], "Content-Type"=>"application/json"} }
    end

    def check
      response = HTTParty.get(uri, request_options)
      events = JSON.parse response.body
      create_event :payload => events
    end
  end
end
