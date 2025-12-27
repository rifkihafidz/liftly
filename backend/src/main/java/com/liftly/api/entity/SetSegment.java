package com.liftly.api.entity;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Entity
@Table(name = "set_segments")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class SetSegment {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne
    @JoinColumn(name = "set_id", nullable = false)
    private WorkoutSet set;

    @Column(nullable = false)
    private Double weight;

    @Column(name = "reps_from", nullable = false)
    private Integer repsFrom;

    @Column(name = "reps_to", nullable = false)
    private Integer repsTo;

    @Column(name = "segment_order", nullable = false)
    private Integer segmentOrder;

    @Column(columnDefinition = "TEXT")
    private String notes;
}
