package com.liftly.api.dto;

import com.fasterxml.jackson.core.JsonParser;
import com.fasterxml.jackson.databind.DeserializationContext;
import com.fasterxml.jackson.databind.JsonDeserializer;
import java.io.IOException;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;

public class TimeDeserializer extends JsonDeserializer<LocalDateTime> {
    private static final DateTimeFormatter TIME_FORMATTER = DateTimeFormatter.ofPattern("HH:mm:ss");

    @Override
    public LocalDateTime deserialize(JsonParser p, DeserializationContext ctxt) throws IOException {
        String value = p.getValueAsString();
        
        if (value == null || value.isEmpty()) {
            return null;
        }

        // Try to parse as HH:mm:ss
        try {
            LocalTime time = LocalTime.parse(value, TIME_FORMATTER);
            // For now, combine with today's date
            // The service layer will handle combining with the actual workout date
            return time.atDate(LocalDate.now());
        } catch (Exception e) {
            // If fails, return null 
            return null;
        }
    }
}

