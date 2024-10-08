require "./player"
require "./non_playable_character"
require "./sign"
require "./dialog"

module RPG
  class Level
    alias AllDialogData = Hash(String, GSF::Dialog::Data)

    getter player : Player
    getter rows : Int32
    getter cols : Int32
    getter player_row : Int32
    getter player_col : Int32
    getter objs : Array(Collidable)
    getter sound_bump : SF::Sound
    getter dialog : Dialog
    getter dialog_key : String

    @dd = AllDialogData.new

    TileSize = 64
    SoundBumpFile = "./assets/sounds/bump.ogg"

    def initialize(@player : Player, @rows = 9, @cols = 9, @player_row = 0, @player_col = 0)
      @objs = [] of Collidable
      @sound_bump = SF::Sound.new(SF::SoundBuffer.from_file(SoundBumpFile))
      @dialog = Dialog.new
      @dialog_key = ""
    end

    def tile_size
      TileSize
    end

    def width
      tile_size * cols
    end

    def height
      tile_size * rows
    end

    def to_tile(col, row)
      {col * tile_size, row * tile_size}
    end

    def start
      init_dialog_data
      dialog.hide_reset

      player.jump_to_tile(player_row, player_col, tile_size)
    end

    def dialog_yml_file
      "./assets/data/dialog/level.yml"
    end

    def init_dialog_data
      data = YAML.parse(File.read(dialog_yml_file))
      data.as_h.each do |key, dialog_data|
        @dd[key.as_s] = GSF::Dialog::Data.new

        dialog_data.as_h.each do |message_key, message_data|
          message = message_data["message"].as_s
          choices = [] of GSF::Message::ChoiceData
          if message_data.as_h.has_key?("choices")
            choices = message_data["choices"].as_a.map do |choice|
              {key: choice["key"].as_s, label: choice["label"].as_s}
            end
          end

          @dd[key][message_key.as_s] = {message: message, choices: choices}
        end
      end
    end

    def dialog_show(key : String, message_key : String)
      @dialog_key = key
      dialog.data = @dd[key]
      dialog.show(message_key)
    end

    def update(frame_time, keys : Keys, mouse : Mouse, joysticks : Joysticks)
      dialog.update(keys, joysticks)

      if choice = dialog.choice_selected
        puts ">>> dialog.choice_selected: #{dialog_key}.#{choice[:key]}"
      end

      return if dialog.show?

      objs.each(&.update(frame_time))

      player.update(frame_time, keys, joysticks, width, height)
      player_collision_checks

      return unless dialog.hide?

      if obj = objs.find(&.check_area_triggered?(player))
        unless obj.dialog_key.empty?
          HUD.action = obj.action

          if keys.just_pressed?([Keys::Enter, Keys::E, Keys::Space]) || joysticks.just_pressed?(Joysticks::A)
            dialog_show(obj.dialog_key, "start")
          end
        end
      end
    end

    def player_collision_checks
      objs.each do |obj|
        collision_x, collision_y = player.collision(obj)

        if collision_x || collision_y
          player.move(-player.dx, 0) if collision_x
          player.move(0, -player.dy) if collision_y

          play_bump_sound

          break
        end
      end
    end

    def play_bump_sound
      return if sound_bump.status.playing?

      sound_bump.pitch = rand(0.9..1.1)
      sound_bump.play
    end

    def draw(window : SF::RenderWindow)
      draw_tiles(window)
      objs.each(&.draw(window))
      player.draw(window)
      dialog.draw(window)
    end

    def draw_tiles(window)
      rows.times do |row|
        cols.times do |col|
          draw_tile(window, col * tile_size, row * tile_size)
        end
      end
    end

    def draw_tile(window, x, y)
    end
  end
end
