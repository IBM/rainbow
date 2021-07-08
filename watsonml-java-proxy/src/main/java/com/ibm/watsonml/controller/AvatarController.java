package com.ibm.watsonml.controller;


import com.ibm.watsonml.service.ScoreEntryService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.concurrent.CompletableFuture;

@RestController
@RequestMapping("/avatar")
public class AvatarController {


    Logger log = LoggerFactory.getLogger(this.getClass().getName());


    @Autowired
    private ScoreEntryService scoreEntryService;


    @GetMapping("/leaderboardAvatar/{id}")
    public CompletableFuture<byte[]> getLeaderBoardAvatar(@PathVariable String id){

        CompletableFuture<byte[]> media = new CompletableFuture<>();
        try {
            media = scoreEntryService.getLeaderBoardAvatar(id);
        } catch (InterruptedException e) {
            log.error("Not able to get image bytes");
            media.completeExceptionally(e);
        }

        return media;
    }


}
