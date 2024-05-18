module RPG
  class Player
    getter x : Int32 | Float32
    getter y : Int32 | Float32
    getter animations

    AnimationFPS = 8
    Size = 64
    Speed = 320
    Sheet = "./assets/player.png"
    ShadowColor = SF::Color.new(31, 31, 31)

    def initialize(x = 0, y = 0)
      # sprite size
      @x = x
      @y = y

      # idle
      idle = GSF::Animation.new(AnimationFPS, loops: false)
      idle.add(Sheet, 0, 0, size, size)

      @animations = GSF::Animations.new(:idle, idle)

      init_animations
    end

    def init_animations
      # idle animation
      idle_animation_frames = 9
      idle_animation = GSF::Animation.new(AnimationFPS, loops: false)

      idle_animation_frames.times do |i|
        idle_animation.add(Sheet, i * size, 0, size, size)
      end

      animations.add(:idle_animation, idle_animation)
      animations.play(:idle_animation)
    end

    def size
      Size
    end

    def update(frame_time, keys : Keys)
      animations.update(frame_time)

      update_movement(frame_time, keys)
    end

    def update_movement(frame_time, keys : Keys)
      dx = 0
      dy = 0

      dy -= 1 if keys.pressed?([Keys::W])
      dx -= 1 if keys.pressed?([Keys::A])
      dy += 1 if keys.pressed?([Keys::S])
      dx += 1 if keys.pressed?([Keys::D])

      return if dx == 0 && dy == 0

      dx, dy = move_with_speed(frame_time, dx, dy)
      dx, dy = move_with_level(dx, dy)

      return if dx == 0 && dy == 0

      move(dx, dy)
    end

    def move_with_speed(frame_time, dx, dy)
      speed = Speed
      directional_speed = dx != 0 && dy != 0 ? speed / 1.4142 : speed
      dx *= (directional_speed * frame_time).to_f32
      dy *= (directional_speed * frame_time).to_f32

      {dx, dy}
    end

    def move_with_level(dx, dy)
      # screen collisions
      dx = 0 if x + dx < 0 || x + dx + size > Screen.width
      dy = 0 if y + dy < 0 || y + dy + size > Screen.height

      {dx, dy}
    end

    def move(dx, dy)
      @x += dx
      @y += dy
    end

    def jump(x, y)
      @x = x
      @y = y
    end

    def draw(window : SF::RenderWindow)
      draw_shadow(window)
      animations.draw(window, x, y - size / 2)
    end

    def draw_shadow(window)
      radius = size / 4
      circle = SF::CircleShape.new(radius)
      circle.fill_color = ShadowColor
      circle.position = {x, y}
      circle.origin = {radius, radius}

      window.draw(circle)
    end
  end
end
