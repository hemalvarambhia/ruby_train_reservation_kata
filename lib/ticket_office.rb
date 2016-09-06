require 'json'
class TicketOffice
  def initialize train_data_service
    @train_data_service = train_data_service
  end

  def make_reservation request
    @train_data_service.reserve_seats(request).to_json
  end
end