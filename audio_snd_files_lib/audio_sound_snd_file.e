note
	description: "Load a fie indo a GAME_AL_SOUND object."
	author: "Louis Marchand"
	date: "May 24, 2012"
	revision: "0.1"

class
	AUDIO_SOUND_SND_FILE

inherit
	AUDIO_SOUND
	DISPOSABLE
	AUDIO_SND_FILES_CONSTANTS

create
	make

feature {NONE} -- Initialization

	make(a_filename:READABLE_STRING_GENERAL)
			-- Initialization for `Current'.
			-- Will use 16 bits signed frames in the buffer.
		do
			make_ressource
			bits_per_sample_internal:=16
			is_signed_internal:=true
			filename:=a_filename
		end

feature {AUDIO_SOURCE}

	fill_buffer(a_buffer:POINTER;a_max_length:INTEGER)
		local
			l_items:INTEGER
		do
			from
				l_items:=a_max_length//2
			until
				(l_items\\byte_per_buffer_sample)=0
			loop
				l_items:=l_items-1
			end
			last_buffer_size:={AUDIO_SND_FILES_EXTERNAL}.sf_read_short(snd_file_ptr,a_buffer,l_items).to_integer*2
		end

	byte_per_buffer_sample:INTEGER
		do
			Result:=2
		end

feature --Access

	is_openable:BOOLEAN
		local
			l_file:RAW_FILE
		do
			create l_file.make_with_name (filename)
			Result:= l_file.exists and l_file.is_readable
		end

	open
		do
			open_from_file(filename)
			is_open:=not has_error
		end

	channel_count:INTEGER
			-- Get the channel number of the sound (1=mono, 2=stereo, etc.).
		do
			Result:={AUDIO_SND_FILES_EXTERNAL}.get_sf_info_struct_channels(file_info)
		end

	frequency:INTEGER
			-- Get the frequency (sample rate) of the sound.
		do
			Result:={AUDIO_SND_FILES_EXTERNAL}.get_sf_info_struct_samplerate(file_info)
		end

	bits_per_sample:INTEGER
			-- Get the bit resolution of one frame of the sound.
		do
			Result:=bits_per_sample_internal
		end

	is_signed:BOOLEAN
			-- Return true if the frames in the buffer are signed.
		do
			Result:=is_signed_internal
		end

	is_seekable:BOOLEAN
			-- Return true if the sound support the seek functionnality.
		do
			Result:=({AUDIO_SND_FILES_EXTERNAL}.get_sf_info_struct_seekable(file_info)/=0)
		end

	restart
			-- Restart the sound to the beginning.
		local
			l_error:INTEGER_64
		do
			if is_seekable then
				l_error:={AUDIO_SND_FILES_EXTERNAL}.SF_seek(snd_file_ptr,0,Seek_set)
				check l_error/=-1 end
			else
				dispose
				open_from_file(filename)
			end

		end

feature {NONE} -- Implementation - Methodes

	open_from_file(a_filename:READABLE_STRING_GENERAL)
		local
			l_filename_c,l_error_c:C_STRING
		do
			file_info:=file_info.memory_alloc (Sf_info_size)
			create l_filename_c.make(a_filename)
			snd_file_ptr:={AUDIO_SND_FILES_EXTERNAL}.SF_open(l_filename_c.item,Sfm_read,file_info)
			if snd_file_ptr.is_default_pointer then
				create l_error_c.make_by_pointer ({AUDIO_SND_FILES_EXTERNAL}.sf_strerror(snd_file_ptr))
				io.error.put_string (l_error_c.string+"%N")
				has_error:=True
			end
		end

	dispose
		local
			error:INTEGER
		do
			file_info.memory_free
			error:={AUDIO_SND_FILES_EXTERNAL}.sf_close(snd_file_ptr)
			check error=0 end
		end

	Sf_info_size:INTEGER
		once
			Result := {AUDIO_SND_FILES_EXTERNAL}.c_sizeof_sf_info
		end

feature {NONE} -- Implementation - Variables

	snd_file_ptr:POINTER
	file_info:POINTER

	bits_per_sample_internal:INTEGER
	is_signed_internal:BOOLEAN

	filename:READABLE_STRING_GENERAL


end
