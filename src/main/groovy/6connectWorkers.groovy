import hudson.model.Node.Mode
import hudson.slaves.*
import jenkins.model.Jenkins
import java.util.logging.Logger
import hudson.model.User
import hudson.security.HudsonPrivateSecurityRealm
import hudson.tasks.Mailer.UserProperty

@Grapes([
    @Grab(group='org.yaml', module='snakeyaml', version='1.17')
])
import org.yaml.snakeyaml.Yaml
import org.yaml.snakeyaml.constructor.SafeConstructor

Logger logger = Logger.getLogger("")
Jenkins jenkins = Jenkins.getInstance()
Yaml yaml = new Yaml(new SafeConstructor())

String configPath = System.getenv("JENKINS_CONFIG_PATH")
try {
    configText = new File("${configPath}/worker_config.yml").text
} catch (FileNotFoundException e) {
    logger.severe("Cannot find config file path @ ${configPath}/worker_config.yml")
    jenkins.doSafeExit(null)
    System.exit(1)
}

workerConfigs = yaml.load(configText)

import hudson.plugins.sshslaves.verifiers.*

SshHostKeyVerificationStrategy hostKeyVerificationStrategy = new NonVerifyingKeyVerificationStrategy()

workerConfigs.each { worker ->
    // There is a constructor that also takes a list of properties (env vars) at the end, but haven't needed that yet
    DumbSlave dumb = new DumbSlave(
            worker.host,  // Agent name, usually matches the host computer's machine name
            worker.description,           // Agent description
            worker.home,                  // Workspace on the agent's computer
            worker.executors,             // Number of executors
            Mode.EXCLUSIVE,             // "Usage" field, EXCLUSIVE is "only tied to node", NORMAL is "any"
            worker.label,                         // Labels
            new hudson.plugins.sshslaves.SSHLauncher(
                worker.host, // Host
                22, // Port
                worker.credential, // Credentials
                (String)null, // JVM Options
                (String)null, // JavaPath
                (String)null, // Prefix Start Slave Command
                (String)null, // Suffix Start Slave Command
                (Integer)null, // Connection Timeout in Seconds
                (Integer)null, // Maximum Number of Retries
                (Integer)null, // The number of seconds to wait between retries
                hostKeyVerificationStrategy // Host Key Verification Strategy
            ),  // Launch strategy
            RetentionStrategy.INSTANCE) // Is the "Availability" field and INSTANCE means "Always"

    jenkins.addNode(dumb)
}
