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
    @seats_on_train = seats_on request[:train_id]

    if percentage_including(request) > 70.percent
      return no_reservation_on request[:train_id]
    end

    reservation = {
      train_id: request[:train_id],
      booking_reference: @booking_reference.new_reference_number,
      seats: first_available_seat(request[:seats])
    }

    response = @train_data_api.reserve reservation

    if response=~/already booked/
      return no_reservation_on(request[:train_id])
    end

    reservation
  end

  private

  def seats_on train_id 
    seats_doc = JSON.parse(@train_data_api.seats_for(train_id))['seats']
    Hash[seats_doc
      .sort_by { |_id, seat| [ seat['seat_number'] ] }
    ]
  end

  def percentage_including request
    number_booked = 
      @seats_on_train.count { |_id, seat| booked? seat } + request[:seats]

    Rational(number_booked, @seats_on_train.size)
  end

  def first_available_seat number
    free_seats = @seats_on_train.select { |_id, seat| free? seat }

    free_seats.keys.first number
  end

  def free? seat
    seat['booking_reference'].empty?
  end

  def no_reservation_on train
    { train_id: train, booking_reference: '', seats: [] }
  end

  def booked? seat
    seat['booking_reference'].size > 0
  end
end
