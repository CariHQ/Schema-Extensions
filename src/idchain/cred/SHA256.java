package idchain.cred;

import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.nio.charset.StandardCharsets;
import io.usethesource.vallang.IValueFactory;
import io.usethesource.vallang.IString;
import io.usethesource.vallang.IInteger;


public class SHA256 {
	protected final IValueFactory vf;
	public SHA256(IValueFactory vf){
			this.vf = vf;
	}
	
	public IInteger toSHA256(IString s) throws NoSuchAlgorithmException  {
		MessageDigest digest = MessageDigest.getInstance("SHA-256");
		return this.vf.integer(digest.digest(s.getValue().getBytes(StandardCharsets.UTF_8)));
	}

}