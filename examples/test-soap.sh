#!/usr/bin/env burl

TEST 1: test a simple Web Service: Add two numbers: 1+2==3

SOAP_REQ \
    'https://ecs.syr.edu/faculty/fawcett/Handouts/cse775/code/calcWebService/Calc.asmx?WSDL' \
    Add `jo a=1 b=2` '.==3'
