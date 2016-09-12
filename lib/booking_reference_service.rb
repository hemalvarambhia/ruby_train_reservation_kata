require 'net/http'
class BookingReferenceService
  def initialize uri
    @uri = uri
  end

  def new_reference_number
    Net::HTTP.get(URI("#{@uri}/booking_reference"))
  end
end