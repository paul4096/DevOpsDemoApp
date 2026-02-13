FROM python:3.12-slim
RUN mkdir /opt/app
WORKDIR /opt/app
COPY requirements.txt /opt/app/
RUN pip install --no-cache-dir -r requirements.txt
COPY app.py /opt/app/
COPY requirements.txt /opt/app/
EXPOSE 8080
CMD ["python", "app.py"]
 
