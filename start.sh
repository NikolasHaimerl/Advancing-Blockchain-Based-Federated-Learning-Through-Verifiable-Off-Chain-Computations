#!/bin/bash
export NODE_OPTIONS=--max-old-space-size=20480
ganache-cli --gasLimit=0x1fffffffffffff  --allowUnlimitedContractSize -e 1000000000

