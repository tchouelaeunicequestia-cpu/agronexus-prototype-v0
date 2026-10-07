package com.agronexus.api.repository;

import com.agronexus.api.entity.ActuatorCommand;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface ActuatorCommandRepository extends JpaRepository<ActuatorCommand, Long> {

    List<ActuatorCommand> findAllByOrderByCreatedAtDesc();
}
