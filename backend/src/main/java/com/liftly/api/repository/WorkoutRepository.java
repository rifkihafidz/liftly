package com.liftly.api.repository;

import com.liftly.api.entity.Workout;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import java.time.LocalDateTime;
import java.util.List;

@Repository
public interface WorkoutRepository extends JpaRepository<Workout, Long> {
    List<Workout> findByUserId(Long userId);
    
    List<Workout> findByUserIdOrderByWorkoutDateDesc(Long userId);
    
    @Query("SELECT w FROM Workout w WHERE w.user.id = :userId AND w.workoutDate BETWEEN :start AND :end ORDER BY w.workoutDate DESC")
    List<Workout> findByUserIdAndWorkoutDateBetween(
        @Param("userId") Long userId,
        @Param("start") LocalDateTime start,
        @Param("end") LocalDateTime end
    );
    
    Workout findByIdAndUserId(Long id, Long userId);
    
    void deleteByUserId(Long userId);
}
