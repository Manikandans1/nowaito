package in.nowaito.auth;

import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.SignatureAlgorithm;
import io.jsonwebtoken.security.Keys;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import javax.crypto.SecretKey;
import java.util.Date;

@Component
public class JwtUtil {

    @Value("${nowaito.jwt.secret}")
    private String secret;

    @Value("${nowaito.jwt.expiry-minutes:1440}")
    private long expiryMinutes;

    private SecretKey key() {
        return Keys.hmacShaKeyFor(secret.getBytes());
    }

    public String issueToken(String subjectId, String role) {
        Date now = new Date();
        Date expiry = new Date(now.getTime() + expiryMinutes * 60_000);
        return Jwts.builder()
                .setSubject(subjectId)
                .claim("role", role)
                .setIssuedAt(now)
                .setExpiration(expiry)
                .signWith(key(), SignatureAlgorithm.HS256)
                .compact();
    }

    public io.jsonwebtoken.Claims parse(String token) {
        return Jwts.parserBuilder().setSigningKey(key()).build().parseClaimsJws(token).getBody();
    }
}
