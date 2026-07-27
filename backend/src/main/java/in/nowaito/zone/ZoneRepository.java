package in.nowaito.zone;

import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface ZoneRepository extends JpaRepository<Zone, UUID> {
    Optional<Zone> findByName(String name);
    List<Zone> findByCity(String city);
    List<Zone> findByActiveTrue();
}
