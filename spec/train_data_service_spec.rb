describe 'Train Data Service' do
  describe '#reserve_seats' do
    describe 'reserving a single seat' do
      context 'when the train is fully-booked' do
        it 'does not reserve the seat'
      end

      context 'when the train has no existing reservations' do
        it 'reserves the first available seat'
      end
      
      context 'when the train is under 70% reserved' do
        context 'and remains so after the reservation' do
          it 'reserves the first available seat'
        end

        context 'but ends up being > 70% reserved after the booking' do
          it 'does not reserve the seat'
        end

        context 'and becomes 70% reserved after the booking' do
          it 'reserves the first available seat'
        end
      end
    end
  end
end
