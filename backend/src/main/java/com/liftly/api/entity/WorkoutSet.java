package com.liftly.api.entity;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.util.ArrayList;
import java.util.List;

@Entity
@Table(name = "workout_sets", indexes = {
    @Index(name = "idx_exercise_id", columnList = "exercise_id"),
    @Index(name = "idx_set_number", columnList = "exercise_id, set_number")
})
@Data
@NoArgsConstructor
@AllArgsConstructor
public class WorkoutSet {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "exercise_id", nullable = false)
    private WorkoutExercise exercise;

    @Column(name = "set_number", nullable = false)
    private Integer setNumber;

    @OneToMany(mappedBy = "set", cascade = CascadeType.ALL, orphanRemoval = true, fetch = FetchType.EAGER)
    @OrderBy("segment_order ASC")
    private List<SetSegment> segments = new ArrayList<>();
}
