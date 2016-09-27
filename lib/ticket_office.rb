require 'json'
class TicketOffice
  def initialize reservation_service
    @reservation_service = reservation_service
  end

  def make_reservation request
    @reservation_service.reserve_seats(request).to_json
  end
end