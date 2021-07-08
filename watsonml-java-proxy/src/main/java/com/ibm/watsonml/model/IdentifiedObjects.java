package com.ibm.watsonml.model;

import java.io.Serializable;
import java.math.BigDecimal;

public class IdentifiedObjects implements Serializable{

    private String name;
    private BigDecimal timestamp;


    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public BigDecimal getTimestamp() {
        return timestamp;
    }

    public void setTimestamp(BigDecimal timestamp) {
        this.timestamp = timestamp;
    }
}
