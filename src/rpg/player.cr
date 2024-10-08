require "./character"
require "./direction"
require "./bag"

module RPG
  class Player < Character
    getter dx : Int32 | Float32
    getter dy : Int32 | Float32
    getter direction : Direction
    getter bag : Bag
    getter? moved

    AxisThreshold = 10

    def initialize(x = 0, y = 0)
      super

      @dx = 0
      @dy = 0
      @direction = Direction::Down
      @bag = Bag.new
      @moved = false
    end

    def update(frame_time, keys : Keys, joysticks : Joysticks, level_width, level_height)
      update_movement_dx_input(keys, joysticks)
      update_movement_dy_input(keys, joysticks)
      update_movement(frame_time, level_width, level_height)

      super(frame_time)
    end

    def update_movement_dx_input(keys, joysticks)
      @dx = 0

      @dx -= 1 if keys.pressed?([Keys::A]) || joysticks.left_stick_moved_left? || joysticks.d_pad_moved_left?
      @dx += 1 if keys.pressed?([Keys::D]) || joysticks.left_stick_moved_right? || joysticks.d_pad_moved_right?
    end

    def update_movement_dy_input(keys, joysticks)
      @dy = 0

      @dy -= 1 if keys.pressed?([Keys::W]) || joysticks.left_stick_moved_up? || joysticks.d_pad_moved_up?
      @dy += 1 if keys.pressed?([Keys::S]) || joysticks.left_stick_moved_down? || joysticks.d_pad_moved_down?
    end

    def update_movement(frame_time, level_width, level_height)
      @moved = false

      return if dx == 0 && dy == 0

      update_dx_with_direction_and_speed(frame_time)
      move_with_level(level_width, level_height)

      return if dx == 0 && dy == 0

      @moved = true
      change_direction
      animate_move(dx, dy)
      move(dx, dy)
    end

    def update_dx_with_direction_and_speed(frame_time)
      directional_speed = dx != 0 && dy != 0 ? Speed / 1.4142 : Speed
      @dx *= (directional_speed * frame_time).to_f32
      @dy *= (directional_speed * frame_time).to_f32
    end

    def move_with_level(level_width, level_height)
      @dx = 0 if x + dx < 0 || x + dx > level_width
      @dy = 0 if y + dy < 0 || y + dy > level_height
    end

    def change_direction
      if dx.abs > 0 && dy.abs > 0
        if dy < 0
          @direction = dx > 0 ? Direction::UpRight : Direction::UpLeft
        else
          @direction = dx > 0 ? Direction::DownRight : Direction::DownLeft
        end
      elsif dy.abs > 0
        @direction = dy < 0 ? Direction::Up : Direction::Down
      elsif dx.abs > 0
        @direction = dx > 0 ? Direction::Right : Direction::Left
      end
    end

    def facing?(other_x, other_y)
      if x > other_x
        if y > other_y
          direction.left_or_up?
        elsif y < other_y
          direction.left_or_down?
        else
          direction.left_any?
        end
      elsif x < other_x
        if y > other_y
          direction.right_or_up?
        elsif y < other_y
          direction.right_or_down?
        else
          direction.right_any?
        end
      else
        if y > other_y
          direction.up_any?
        elsif y < other_y
          direction.down_any?
        else
          true
        end
      end
    end

    def collision(obj : Collidable) : Tuple(Bool, Bool)
      x = @x - dx
      y = @y - dy

      collides_x = x + dx - collision_width / 2 < obj.x + obj.collision_width / 2 &&
        x + dx + collision_width / 2 > obj.x - obj.collision_width / 2 &&
        y + collision_height / 2 > obj.y - obj.collision_height / 2 &&
        y - collision_height / 2 < obj.y + obj.collision_height / 2

      collides_y = y + dy - collision_height / 2 < obj.y + obj.collision_height / 2 &&
        y + dy + collision_height / 2 > obj.y - obj.collision_height / 2 &&
        x + collision_width / 2 > obj.x - obj.collision_width / 2 &&
        x - collision_width / 2 < obj.x + obj.collision_width / 2

      {collides_x, collides_y}
    end
  end
end
