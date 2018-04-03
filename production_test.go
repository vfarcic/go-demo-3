package main

import (
	"fmt"
	"github.com/stretchr/testify/suite"
	"net/http"
	"os"
	"strconv"
	"testing"
	"time"
)

type ProductionTestSuite struct {
	suite.Suite
	hostIp string
}

func TestProductionTestSuite(t *testing.T) {
	s := new(ProductionTestSuite)
	s.hostIp = os.Getenv("HOST_IP")
	suite.Run(t, s)
}

func (s *ProductionTestSuite) SetupTest() {
}

// Production

func (s ProductionTestSuite) Test_Hello_ReturnsStatus200() {
	start := time.Now()
	if len(os.Getenv("DURATION")) > 0 {
		max, _ := strconv.ParseFloat(os.Getenv("DURATION"), 64)
		minutes := float64(0)
		counter := 0
		for time.Since(start).Minutes() < max {
			address := fmt.Sprintf("http://%s/demo/hello", s.hostIp)
			resp, err := http.Get(address)
			counter++
			if err != nil {
				msg := fmt.Sprintf("Failed on request %d with error %s", counter, err.Error())
				s.Fail(msg)
				break
			} else if resp == nil {
				msg := fmt.Sprintf("Failed on request %d with no response", counter)
				s.Fail(msg)
				break
			} else if resp.StatusCode != 200 {
				msg := fmt.Sprintf("Response status code is %d", resp.StatusCode)
				s.Fail(msg)
				break
			}
			if time.Since(start).Minutes() > minutes {
				fmt.Printf("%2.0f out of %2.0f minutes passed\n", minutes, max)
				minutes++
			}
			time.Sleep(1 * time.Second)
		}
	} else {
		address := fmt.Sprintf("http://%s/demo/hello", s.hostIp)
		resp, err := http.Get(address)

		if err != nil {
			s.Fail(err.Error())
		} else if resp == nil {
			s.Fail("Got no response")
		} else {
			s.Equal(200, resp.StatusCode)
		}
	}
}
