class Run < ActiveRecord::Base
  belongs_to :provider
  belongs_to :driver
  belongs_to :vehicle

  has_many :trips, -> { order(:pickup_time) }, :dependent => :nullify

  before_validation :fix_dates, :set_complete

  has_paper_trail

  accepts_nested_attributes_for :trips

  validates_datetime :scheduled_end_time, :after => :scheduled_start_time, :allow_blank => true
  validates_datetime :actual_end_time, :after => :actual_start_time, :allow_blank => true
  validates_date :date
  validates_numericality_of :start_odometer, :allow_nil => true
  validates_numericality_of :end_odometer, :allow_nil => true
  validates_numericality_of :end_odometer, :allow_nil => true,
    :greater_than => Proc.new {|run| run.start_odometer },
    :if => Proc.new {|run| run.start_odometer.present? }
  validates_numericality_of :end_odometer, :allow_nil => true,
    :less_than => Proc.new {|run| run.start_odometer + 500 },
    :if => Proc.new {|run| run.start_odometer.present? }
  validates_numericality_of :unpaid_driver_break_time, :allow_nil => true

  scope :for_provider,           -> (provider_id) { where( :provider_id => provider_id ) }
  scope :for_vehicle,            -> (vehicle_id) { where(:vehicle_id => vehicle_id )}
  scope :for_paid_driver,        -> { where(:paid => true) }
  scope :for_volunteer_driver,   -> { where(:paid => false) }
  scope :incomplete_on,          -> (date) { where(:complete => false, :date => date) }
  scope :for_date_range,         -> (start_date, end_date) { where("runs.date >= ? and runs.date < ?", start_date, end_date) }
  scope :with_odometer_readings, -> { where("start_odometer IS NOT NULL and end_odometer IS NOT NULL") }
  scope :includes_funding_source,-> (funding_source_id) { where("runs.id IN (SELECT run_id FROM trips where COALESCE(funding_source_id,-1) = ?)", (funding_source_id || -1)) }

  def cab=(value)
    @cab = value
  end

  def vehicle_name
    vehicle.name if vehicle.present?
  end

  def label
    if @cab
      "Cab"
    else
      "#{vehicle_name}: #{driver.try :name} #{scheduled_start_time.try :strftime, "%I:%M%P"}".gsub( /m$/, "" )
    end
  end

  def as_json(options)
    { :id => id, :label => label }
  end

  def apportion_hours_and_miles!
    r = self.trips.completed
    trip_count = r.count
    if trip_count > 0
      ratio = 1 / trip_count.to_f

      unless actual_end_time.nil? || actual_start_time.nil?
        run_duration = (actual_end_time - actual_start_time)
        trip_duration = (run_duration * ratio).floor
        run_duration_remaining = run_duration
      end

      unless start_odometer.nil? || end_odometer.nil?
        run_mileage = end_odometer - start_odometer
        trip_mileage = ((run_mileage * ratio) * 100).floor.to_f / 100
        run_mileage_remaining = run_mileage
      end

      trip_position = 0

      r.each do |t|
        trip_position += 1

        unless trip_duration.nil?
          run_duration_remaining = (run_duration_remaining - trip_duration)
          t.apportioned_duration = (trip_duration + (trip_position == trip_count ? run_duration_remaining : 0))
        end

        unless trip_mileage.nil?
          run_mileage_remaining = (run_mileage_remaining - trip_mileage).round(2)
          t.apportioned_mileage = (trip_mileage + (trip_position == trip_count ? run_mileage_remaining : 0)).round(2)
        end

        t.save!
      end
    end
  end

  private

  def set_complete
    self.complete = ((!actual_start_time.nil?) && (!actual_end_time.nil?) && actual_end_time < DateTime.now && vehicle_id && driver_id && start_odometer && end_odometer && (trips.none? &:pending))
    true
  end

  def fix_dates
    d = self.date
    unless d.nil?
      unless scheduled_start_time.nil?
        s = scheduled_start_time
        self.scheduled_start_time = Time.zone.local(d.year, d.month, d.day, s.hour, s.min, 0)
        scheduled_start_time_will_change!
      end
      unless scheduled_end_time.nil?
        s = scheduled_end_time
        self.scheduled_end_time = Time.zone.local(d.year, d.month, d.day, s.hour, s.min, 0)
        scheduled_end_time_will_change!
      end
      unless actual_start_time.nil?
        a = actual_start_time
        self.actual_start_time = Time.zone.local(d.year, d.month, d.day, a.hour, a.min, 0)
        actual_start_time_will_change!
      end
      unless actual_end_time.nil?
        a = actual_end_time
        self.actual_end_time = Time.zone.local(d.year, d.month, d.day, a.hour, a.min, 0)
        actual_end_time_will_change!
      end
    end
    true
  end

end
