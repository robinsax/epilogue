from common import pick_implementation

class Matchmaker:

    def match(self, queue: list) -> list[list]:
        raise NotImplementedError()

class SimpleMatchmaker:

    def match(self, queue: list) -> list[list]:
        matched = list()

        p_count = 1

        while len(queue) >= p_count:
            players = list()
            for i in range(p_count):
                players.append(queue.pop())
            matched.append(players)

        return matched

def get_matchmaker() -> Matchmaker:
    impl = pick_implementation('MATCHMAKER', {
        'simple': SimpleMatchmaker
    })

    return impl()
