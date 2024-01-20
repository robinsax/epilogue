import os
import random
import subprocess

from .common import pick_implementation

class InfraError(BaseException): pass

class InfraDriver:

    def allocate(self, match: dict) -> str: # ret addr.
        raise NotImplementedError()

    def deallocate(self, match: dict):
        raise NotImplementedError()

class DockerInfraDriver(InfraDriver):
    ports: dict

    def __init__(self):
        super().__init__()
        self.ports = dict()

    def allocate(self, match: dict) -> str:
        match_id = str(match['_id'])

        port = 5000
        while port in self.ports:
            port = random.randint(5000, 8000)
        port = str(port)
        self.ports[port] = match_id

        result = subprocess.run(
            f'''
            docker run
                --detach
                --name match-{ match_id }
                --network internal
                --publish 127.0.0.1:{ port }:{ port }/tcp
                --publish 127.0.0.1:{ port }:{ port }/udp
                --env MATCH_ID={ match_id }
                --env PORT={ port }
                --env DATABASE_URI={ os.environ['DATABASE_URI'] }
                server:latest
            '''.strip().split(),
            stderr=subprocess.PIPE,
            stdout=subprocess.PIPE
        )
        print(result.stdout)

        if result.returncode != 0:
            raise InfraError(result.stderr)
        
        return f'127.0.0.1:{ port }'

    def deallocate(self, match: dict):
        match_id = str(match['_id'])

        result = subprocess.run(
            f'''
            docker kill match-{ match_id }                        
            '''.strip().split(),
            stderr=subprocess.PIPE,
            stdout=subprocess.PIPE
        )
        print(result.stdout)

        if result.returncode != 0:
            print('warn: kill attempt on dead server')
            print(result.stderr)

        for key in self.ports:
            if self.ports[key] == match_id:
                del self.ports[key]
                break

def get_infra_driver() -> InfraDriver:
    impl = pick_implementation('INFRA_DRIVER', {
        'docker': DockerInfraDriver
    })

    return impl()
