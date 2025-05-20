package klaxon.klaxon.inspector;

import static java.lang.System.out;

import org.openjdk.jol.info.ClassLayout;
import org.openjdk.jol.vm.VM;

public class Inspector {
    public static void main(String[] args) {
        out.println(VM.current().details());
        out.println(ClassLayout.parseClass(int[].class).toPrintable());
    }
}
