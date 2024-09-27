package main

import SDL "vendor:sdl2"
import "core:os"
import "core:fmt"
import "core:time"
import win32 "core:sys/windows"

main :: proc() {
	when ODIN_DEBUG { fmt.println("DEBUG") }

	// SDL Init
	SDL.Init(SDL.INIT_EVERYTHING)
	defer SDL.Quit()
	win_ptr := SDL.CreateWindow("",
		SDL.WINDOWPOS_CENTERED,
		SDL.WINDOWPOS_CENTERED,
		600,400,
		transmute(SDL.WindowFlags)cast(u32)0
	)
	defer SDL.DestroyWindow(win_ptr)
	rdr_ptr := SDL.CreateRenderer(win_ptr,-1,SDL.RENDERER_ACCELERATED)
	defer SDL.DestroyRenderer(rdr_ptr)
	
	//State Decleration
	nextFrame : u64 = GetRealtimeCount()
	nextSecond := nextFrame
	tickFreq := GetRealtimeFreq()
	fps_limit := tickFreq / 60
	fps : u32
	box := SDL.Rect{0,0,2,400}

	delayCount := 0

	// Program Loop
	mainloop : for {
		// EventLoop
		for e:SDL.Event;SDL.PollEvent(&e);{
			#partial switch e.type {
			case SDL.EventType.QUIT: break mainloop
			}
		}

		// MainLoop
		if GetRealtimeCount() >= nextFrame {
			frameSkips : u64

			for firstRun := true; firstRun || (GetRealtimeCount() >= nextFrame && frameSkips < 5); firstRun = false {
				frameSkips += 1
				/* Game Logic */{
					box.x += 2
					if box.x == 600 do box.x = 0
				}
				nextFrame += fps_limit
			}

			fps+=1

			if GetRealtimeCount() >= nextSecond {
				SDL.SetWindowTitle(win_ptr,fmt.caprintf("FPS %d : Freed CPU %d times DEBUG" when ODIN_DEBUG else "FPS %d : Freed CPU %d times",fps,delayCount))
				delayCount = 0
				fps = 0
				nextSecond += tickFreq
			}

			{ using SDL
				SetRenderDrawColor(rdr_ptr,0x08,0x08,0x16,0xFF)
				RenderClear(rdr_ptr)
				SetRenderDrawColor(rdr_ptr,0xFF,0x00,0x22,0xFF)
				RenderFillRect(rdr_ptr,&box)
				RenderPresent(rdr_ptr)
			}

		} else {
			SDL.Delay(1)
			delayCount += 1
		}
	}
}

GetRealtimeCount :: proc "contextless" () -> u64 {
	realtime : win32.LARGE_INTEGER
	win32.QueryPerformanceCounter(&realtime)
	return u64(realtime)
}

GetRealtimeFreq :: proc "contextless" () -> u64 {
	freq : win32.LARGE_INTEGER
	win32.QueryPerformanceFrequency(&freq)
	return u64(freq)
}
