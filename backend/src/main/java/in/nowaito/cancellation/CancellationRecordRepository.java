package in.nowaito.cancellation;

import org.springframework.data.jpa.repository.JpaRepository;

import java.util.UUID;

public interface CancellationRecordRepository extends JpaRepository<CancellationRecord, UUID> {
}
