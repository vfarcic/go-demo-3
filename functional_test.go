package main

import (
	"fmt"
	"github.com/stretchr/testify/suite"
	"net/http"
	"os"
	"testing"
)

type FunctionalTestSuite struct {
	suite.Suite
	hostIp      string
	servicePath string
}

func TestFunctionalTestSuite(t *testing.T) {
	s := new(FunctionalTestSuite)
	s.hostIp = os.Getenv("HOST_IP")
	s.servicePath = "/demo"
	if len(os.Getenv("SERVICE_PATH")) > 0 {
		s.servicePath = os.Getenv("SERVICE_PATH")
	}
	suite.Run(t, s)
}


func (s *FunctionalTestSuite) SetupTest() {
}

// Functional

func (s FunctionalTestSuite) Test_Hello_ReturnsStatus200() {
	address := fmt.Sprintf("http://%s%s/hello", s.hostIp, s.servicePath)
	resp, err := http.Get(address)

	s.NoError(err)
	s.Equal(200, resp.StatusCode, "ADDR: ", address)
}

func (s FunctionalTestSuite) Test_Person_ReturnsStatus200() {
	address := fmt.Sprintf("http://%s%s/person", s.hostIp, s.servicePath)
	resp, err := http.Get(address)

	s.NoError(err)
	s.Equal(200, resp.StatusCode, "ADDR: %s", address)
}
