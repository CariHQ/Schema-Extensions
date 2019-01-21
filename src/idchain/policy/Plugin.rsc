module idchain::policy::Plugin

import idchain::policy::Policy;
import ParseTree;
import util::IDE;

void main() {
  registerLanguage("IdentityPolicy", "idpolicy", start[Policy](str src, loc org) {
    return parse(#start[Policy], src, org);
  });
}