package com.ibm.watsonml.model;

import java.io.Serializable;
import java.math.BigDecimal;
import java.util.List;

public class ScoreEntry implements Serializable{

    private String id;
    private String username;
    private BigDecimal startDate;
    private BigDecimal finishDate;
    private String deviceIdentifier;
    private String avatarImage;
    List<IdentifiedObjects> objects;
    Double totalTime;

    public String getId() {
        return id;
    }

    public void setId(String id) {
        this.id = id;
    }

    public String getUsername() {
        return username;
    }

    public void setUsername(String username) {
        this.username = username;
    }

    public BigDecimal getStartDate() {
        return startDate;
    }

    public void setStartDate(BigDecimal startDate) {
        this.startDate = startDate;
    }

    public BigDecimal getFinishDate() {
        return finishDate;
    }

    public void setFinishDate(BigDecimal finishDate) {
        this.finishDate = finishDate;
    }

    public String getDeviceIdentifier() {
        return deviceIdentifier;
    }

    public void setDeviceIdentifier(String deviceIdentifier) {
        this.deviceIdentifier = deviceIdentifier;
    }

    public String getAvatarImage() {
        return avatarImage;
    }

    public void setAvatarImage(String avatarImage) {
        this.avatarImage = avatarImage;
    }

    public List<IdentifiedObjects> getObjects() {
        return objects;
    }

    public void setObjects(List<IdentifiedObjects> objects) {
        this.objects = objects;
    }

    public Double getTotalTime() {
        return totalTime;
    }

    public void setTotalTime(Double totalTime) {
        this.totalTime = totalTime;
    }
}
