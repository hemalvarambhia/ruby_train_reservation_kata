require 'json'
class Fixnum
  def percent
    Rational(self, 100)
  end
end

class TrainDataService
  def initialize(train_data_api, booking_reference_service)
    @train_data_api = train_data_api
    @booking_reference = booking_reference_service
  end

  def reserve_seats request
    @train = train_with_id request[:train_id]
    coach = @train.find { |coach| coach.underbooked? request }
    reservation = 
      if coach.nil?
        no_reservation_on request[:train_id]
      else
        coach.make_reservation(
          request, @booking_reference.new_reference_number)
      end

    response = @train_data_api.reserve reservation

    if response=~/already booked/
      return no_reservation_on(request[:train_id])
    end

    reservation
  end

  private

  def train_with_id train_id
    seats_doc = JSON.parse(
      @train_data_api.seats_for(train_id), symbolize_names: true)[:seats]
    all_seats = seats_doc.map { |_, seat| Seat.new seat }
    all_seats.group_by { |seat| seat.coach }.map do |_, seats|
      Coach.new seats
    end
  end

  def no_reservation_on train
    { train_id: train, booking_reference: '', seats: [] }
  end

  class Coach
    def initialize seats
      @seats = seats.sort_by { |seat| seat.seat_number }
    end

    def make_reservation(request, booking_ref)
      {
        train_id: request[:train_id],
        booking_reference: booking_ref,
        seats: first_free_seats(request)
      }
    end

    def first_free_seats request
      @seats.select { |seat| seat.free? }.map { |seat| seat.id }
        .first request[:seats] 
    end

    def underbooked? request
      number_booked =
        @seats.count { |seat| seat.booked? } + request[:seats]

      Rational(number_booked, @seats.size) <= 70.percent
    end
  end

  class Seat
    def initialize args
      @args = args
    end

    def seat_number
      @args[:seat_number]
    end

    def coach
      @args[:coach]
    end

    def id
      "#{@args[:seat_number]}#{@args[:coach]}"
    end

    def booked?
      @args[:booking_reference].size > 0
    end

    def free?
      !booked?
    end
  end
end
