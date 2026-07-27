package in.nowaito.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.web.SecurityFilterChain;

@Configuration
public class SecurityConfig {

    @Bean
    public SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
        http
            .csrf(csrf -> csrf.disable())
            .sessionManagement(sm -> sm.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
            .authorizeHttpRequests(auth -> auth
                // Open for the pilot so you can test end-to-end immediately.
                // TODO before any real money/PII flows: add a JwtAuthFilter that reads the
                // Authorization: Bearer <token> header (see auth.JwtUtil) and restricts
                // /api/drivers/**, /api/trips/**, /api/bookings/** to the authenticated owner.
                .anyRequest().permitAll()
            );
        return http.build();
    }
}
