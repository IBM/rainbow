package com.ibm.watsonml.controller;


import com.ibm.watsonml.model.ScoreEntry;
import com.ibm.watsonml.service.ScoreEntryService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import javax.servlet.http.HttpServletRequest;
import java.util.List;
import java.util.concurrent.CompletableFuture;

@RestController
@RequestMapping("/watsonml")
public class ScoreEntryController {

    Logger log = LoggerFactory.getLogger(this.getClass().getName());


    @Autowired
    private ScoreEntryService scoreEntryService;


    @PostMapping("/entries")
    public CompletableFuture<ScoreEntry> saveUserData(HttpServletRequest request, @RequestBody ScoreEntry scoreEntry) {
        log.debug("REST request to save user score");
        CompletableFuture<ScoreEntry> entries = new CompletableFuture<>();
        try {
            entries.complete(scoreEntryService.saveUserScore(scoreEntry).get());
        } catch (Exception e) {
            log.error("Error while making external API call {}", e);
            entries.completeExceptionally(e);
        }
        return entries;
    }

    @PutMapping("/entries/{identifier}")
    public CompletableFuture<ScoreEntry> updateUserData(@RequestBody ScoreEntry scoreEntry,@PathVariable String identifier) {
        log.debug("REST request to update user score");
        CompletableFuture<ScoreEntry> entries = new CompletableFuture<>();
        try {
            entries.complete(scoreEntryService.updateUserScore(scoreEntry).get());
        } catch (Exception e) {
            log.error("Error while making external API call {}", e);
            entries.completeExceptionally(e);
        }
        return entries;
    }


    @GetMapping("/leaderboard")
    public CompletableFuture<List<ScoreEntry>> getLeaderBoard() {
        log.debug("REST request to get leaderboard");
        CompletableFuture<List<ScoreEntry>> entries = new CompletableFuture<>();
        try {
            entries.complete(scoreEntryService.getLeaderBoard().get());
        } catch (Exception e) {
            log.error("Error while making external API call {}", e);
            entries.completeExceptionally(e);
        }
        return entries;
    }
}
