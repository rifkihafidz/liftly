package com.liftly.api.repository;

import com.liftly.api.entity.Workout;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.time.LocalDateTime;
import java.util.List;

@Repository
public interface WorkoutRepository extends JpaRepository<Workout, Long> {
    List<Workout> findByUserId(Long userId);
    List<Workout> findByUserIdOrderByWorkoutDateDesc(Long userId);
    List<Workout> findByUserIdAndWorkoutDateBetween(Long userId, LocalDateTime start, LocalDateTime end);
    Workout findByIdAndUserId(Long id, Long userId);
}
