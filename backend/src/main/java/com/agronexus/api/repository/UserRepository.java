package com.agronexus.api.repository;

import com.agronexus.api.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;
import java.util.List;

/**
 * ==============================================================================
 * AgroNexus User Repository
 *
 * WHY: Provides database access methods for User entity.
 * HOW: Extends JpaRepository for standard CRUD. findByEmail() is used by
 *      AuthController (login) and JwtAuthFilter (token validation).
 * ==============================================================================
 */
@Repository
public interface UserRepository extends JpaRepository<User, Long> {

    // Used by AuthController login and JwtAuthFilter to look up users by email
    Optional<User> findByEmail(String email);

    Optional<User> findByGoogleSubject(String googleSubject);

    List<User> findByIsVerifiedFalse();
}
