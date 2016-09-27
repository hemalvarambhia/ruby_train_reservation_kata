require 'net/http'
require 'json'
class TrainDataAPI
  def initialize uri
    @uri = uri
  end

  def seats_for train_id
    Net::HTTP.get(URI("#{@uri}/data_for_train/#{train_id}"))
  end

  def reserve reservation
    with_seats_in_json = {
      train_id: reservation[:train_id],
      booking_reference: reservation[:booking_reference],
      seats: reservation[:seats].to_json
    }
    response = 
      Net::HTTP.post_form(URI("#{@uri}/reserve"), with_seats_in_json)

    response.body
  end
end