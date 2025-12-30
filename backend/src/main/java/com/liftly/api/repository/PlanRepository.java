package com.liftly.api.repository;

import com.liftly.api.entity.Plan;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface PlanRepository extends JpaRepository<Plan, Long> {
    List<Plan> findByUserId(Long userId);
    Plan findByIdAndUserId(Long id, Long userId);
    void deleteByUserId(Long userId);
}
