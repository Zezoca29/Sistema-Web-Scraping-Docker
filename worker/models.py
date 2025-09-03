from sqlalchemy.orm import declarative_base
from sqlalchemy import Column, Integer, Text, TIMESTAMP
from sqlalchemy.sql import func


Base = declarative_base()


class PageResult(Base):
__tablename__ = "page_results"


id = Column(Integer, primary_key=True)
url = Column(Text, nullable=False)
status_code = Column(Integer)
title = Column(Text)
description = Column(Text)
duration_ms = Column(Integer)
error = Column(Text)
fetched_at = Column(TIMESTAMP, server_default=func.now())