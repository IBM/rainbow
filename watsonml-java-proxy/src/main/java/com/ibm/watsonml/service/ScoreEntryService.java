package com.ibm.watsonml.service;


import com.ibm.watsonml.model.ScoreEntry;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.*;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.client.RestTemplate;

import javax.servlet.http.HttpServletRequest;
import java.util.Arrays;
import java.util.List;
import java.util.concurrent.CompletableFuture;

@Service
@Transactional
public class ScoreEntryService {

    private final Logger log = LoggerFactory.getLogger(ScoreEntryService.class);

    @Autowired
    private RestTemplate restTemplate;

    @Value("${application.kituraUrl.save.score}")
    private String saveScoreEntryURL;

    @Value("${application.kituraUrl.update.score}")
    private String updateScoreEntryURL;

    @Value("${application.kituraUrl.get.leaderboard}")
    private String getLeaderBoardURL;

    @Autowired
    HttpServletRequest request;

    private HttpHeaders getHeader() {
        HttpHeaders headers = new HttpHeaders();
        headers.set("Authorization", request.getHeader("Authorization"));
        headers.setContentType(MediaType.APPLICATION_JSON);
        return headers;
    }


    /**
     * Method to asynchronously call external API
     * @return
     * @throws InterruptedException
     */
    @Async
    public CompletableFuture<ScoreEntry> saveUserScore(ScoreEntry scoreEntry) throws InterruptedException{
        log.info("Saving Score entry to database.");

        HttpHeaders headers = getHeader();
        ResponseEntity<ScoreEntry> response=restTemplate.exchange
                (saveScoreEntryURL, HttpMethod.POST, new HttpEntity<>(scoreEntry, headers), ScoreEntry.class);

        // delay of 1s
        Thread.sleep(1000L);
        return CompletableFuture.completedFuture(response.getBody());
    }


    /**
     * Method to asynchronously call external API
     * @return
     * @throws InterruptedException
     */
    @Async
    public CompletableFuture<ScoreEntry> updateUserScore(ScoreEntry scoreEntry) throws InterruptedException{
        log.info("Updating Score entry to database.");

        String updateURL = new StringBuilder(saveScoreEntryURL).append("/").append(scoreEntry.getId()).toString();

        HttpHeaders headers = getHeader();
        ResponseEntity<ScoreEntry> response=restTemplate.exchange
                (updateURL, HttpMethod.PUT, new HttpEntity<>(scoreEntry, headers), ScoreEntry.class);

        // delay of 1s
        Thread.sleep(1000L);
        return CompletableFuture.completedFuture(response.getBody());
    }

    /**
     * Method to asynchronously call external API
     * @return
     * @throws InterruptedException
     */
    @Async
    public CompletableFuture<List<ScoreEntry>> getLeaderBoard() throws InterruptedException{
        log.info("Getting leaderboard data.");

        HttpHeaders headers = getHeader();
        ResponseEntity<ScoreEntry[]> response=restTemplate.exchange
                (getLeaderBoardURL, HttpMethod.GET, new HttpEntity<>( headers), ScoreEntry[].class);

        // delay of 1s
        Thread.sleep(1000L);
        return CompletableFuture.completedFuture(Arrays.asList(response.getBody()));
    }
}
