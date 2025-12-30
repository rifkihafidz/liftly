package com.liftly.api.entity;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.util.ArrayList;
import java.util.List;

@Entity
@Table(name = "workout_exercises", indexes = {
    @Index(name = "idx_workout_id", columnList = "workout_id"),
    @Index(name = "idx_exercise_order", columnList = "workout_id, exercise_order")
})
@Data
@NoArgsConstructor
@AllArgsConstructor
public class WorkoutExercise {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "workout_id", nullable = false)
    private Workout workout;

    @Column(nullable = false)
    private String name;

    @Column(name = "exercise_order", nullable = false)
    private Integer order;

    @Column(nullable = false)
    private Boolean skipped = false;

    @OneToMany(mappedBy = "exercise", cascade = CascadeType.ALL, orphanRemoval = true, fetch = FetchType.EAGER)
    @OrderBy("set_number ASC")
    private List<WorkoutSet> sets = new ArrayList<>();
}
