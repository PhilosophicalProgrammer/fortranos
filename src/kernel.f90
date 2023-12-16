program test
    ! Include C types for raw memory access
    use iso_c_binding
    implicit none

    ! Include an external assembly function that halts the CPU when we're done to save power
    external halt_cpu

    character(24) :: greeting
    integer(kind = 8) :: char_index
    integer(kind = 1), pointer :: character_buffer(:)
    integer(kind = 1), pointer :: video_memory_buffer(:)

    greeting = "Hello from Fortran 2003!"
    character_buffer => address_to_buffer(loc(greeting))

    ! Each slot in the VGA text-mode video memory buffer, located at address 0xB8000,
    ! consists of two bytes, the first representing the character code and the second
    ! representing the color of the character. The upper four bits of the color represent
    ! the background color of the character and the lower four bits represent the foreground
    ! color, i.e. the color of the character itself. 
    !
    ! You can find a list of VGA color codes here, specifically in the 4-bit-modes section
    ! of the page: https://www.fountainware.com/EXPL/vga_color_palettes.htm  
    video_memory_buffer => address_to_buffer(int(Z"B8000", 8))

    ! The default resolution of the text mode an x86 computer boots up in is almost always
    ! 80x25. We clear out the screen with a green background using this information.
    
    do char_index = 0, 80 * 25 - 1
        video_memory_buffer(char_index * 2 + 1) = 32 ! ASCII character code for a space
        video_memory_buffer(char_index * 2 + 2) = lshift(2, 4) ! 2 is the 4-bit color code for green
    end do

    do char_index = 1, len(greeting)
        video_memory_buffer((char_index - 1) * 2 + 1) = character_buffer(char_index)
        video_memory_buffer((char_index - 1) * 2 + 2) = 1 + lshift(2, 4) ! Blue foreground, green background
    end do
    
    ! This is much more power efficient than doing a spin loop.
    call halt_cpu()

    contains
        function address_to_buffer(address)
            type(c_ptr) :: cptr
            integer(kind = 8) :: address
            integer(kind = 1), pointer :: address_to_buffer(:)

            cptr = transfer(address, cptr)
            call c_f_pointer(cptr, address_to_buffer, [50])
        end function address_to_buffer
end program test