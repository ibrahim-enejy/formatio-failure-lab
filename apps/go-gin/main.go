package main

import (
	"fmt"
	"net/http"
	"os"
	"runtime"
	"strconv"
	"time"

	"github.com/gin-gonic/gin"
)

var startTime = time.Now()

func main() {
	r := gin.Default()

	// Healthcheck probe (Scenario 08: returns 503 when SIMULATE_BAD_HEALTHCHECK=true)
	r.GET("/healthz", func(c *gin.Context) {
		if os.Getenv("SIMULATE_BAD_HEALTHCHECK") == "true" {
			c.JSON(http.StatusServiceUnavailable, gin.H{
				"status": "unhealthy",
				"reason": "SIMULATE_BAD_HEALTHCHECK=true",
			})
			return
		}
		c.JSON(http.StatusOK, gin.H{
			"status":  "ok",
			"service": "go-gin",
		})
	})

	// Root Index
	r.GET("/", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{
			"lab":           "Formatio Open-Source Failure Lab",
			"framework":     "Go / Gin",
			"telemetry_url": "/api/lab/status",
			"scenarios": gin.H{
				"01-oom":            "POST /api/lab/scenarios/01-oom",
				"02-hang":           "POST /api/lab/scenarios/02-hang",
				"06-goroutine-leak": "POST /api/lab/scenarios/06-goroutine-leak?count=50000",
			},
		})
	})

	// Telemetry & Status
	r.GET("/api/lab/status", func(c *gin.Context) {
		var m runtime.MemStats
		runtime.ReadMemStats(&m)

		c.JSON(http.StatusOK, gin.H{
			"status": "online",
			"app":    "Formatio Failure Lab — Go/Gin Microservice",
			"runtime": gin.H{
				"go_version":     runtime.Version(),
				"os":             runtime.GOOS,
				"arch":           runtime.GOARCH,
				"num_cpu":        runtime.NumCPU(),
				"num_goroutines": runtime.NumGoroutine(),
				"uptime_seconds": int(time.Since(startTime).Seconds()),
			},
			"memory": gin.H{
				"alloc_mb":       bToMb(m.Alloc),
				"total_alloc_mb": bToMb(m.TotalAlloc),
				"sys_mb":         bToMb(m.Sys),
				"num_gc":         m.NumGC,
			},
			"scenarios": gin.H{
				"01-heap-oom":       "POST /api/lab/scenarios/01-oom",
				"02-hang":           "POST /api/lab/scenarios/02-hang",
				"06-goroutine-leak": "POST /api/lab/scenarios/06-goroutine-leak",
			},
		})
	})

	// Scenario 01: Unbounded Heap Allocation
	r.POST("/api/lab/scenarios/01-oom", func(c *gin.Context) {
		fmt.Println("[Sabotage] Starting unbounded memory allocation in Go heap...")
		var leak [][]byte
		for {
			chunk := make([]byte, 10*1024*1024) // 10MB
			for i := range chunk {
				chunk[i] = 1
			}
			leak = append(leak, chunk)
		}
	})

	// Scenario 02: Upstream Connection Starvation
	r.POST("/api/lab/scenarios/02-hang", func(c *gin.Context) {
		fmt.Println("[Sabotage] Simulating 15-second upstream timeout...")
		time.Sleep(15 * time.Second)
		c.JSON(http.StatusOK, gin.H{
			"status":  "resolved",
			"message": "Upstream slow dependency resolved after 15s.",
		})
	})

	// Scenario 06: Unbounded Goroutine Starvation / Leak
	r.POST("/api/lab/scenarios/06-goroutine-leak", func(c *gin.Context) {
		countStr := c.DefaultQuery("count", "50000")
		count, err := strconv.Atoi(countStr)
		if err != nil || count <= 0 {
			count = 50000
		}

		fmt.Printf("[Sabotage] Spawning %d abandoned goroutines waiting on nil channel...\n", count)
		for i := 0; i < count; i++ {
			go func() {
				// Block indefinitely on unbuffered channel with no sender
				ch := make(chan struct{})
				<-ch
			}()
		}

		c.JSON(http.StatusOK, gin.H{
			"status":                    "triggered",
			"scenario":                  "06-goroutine-leak",
			"goroutines_spawned":        count,
			"current_active_goroutines": runtime.NumGoroutine(),
			"message":                   "Goroutines spawned and permanently leaked in memory.",
		})
	})

	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}
	r.Run(":" + port)
}

func bToMb(b uint64) float64 {
	return float64(b) / 1024 / 1024
}
