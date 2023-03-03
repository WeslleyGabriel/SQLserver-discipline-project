--Weslley Gabriel


/*1) Execute os scripts disponibilizados para criar e preencher as tabelas da base que dever�
ser utilizada.*/

CREATE DATABASE CopaDoMundo

USE CopaDoMundo

SET DATEFORMAT dmy

CREATE TABLE Estadios(
	idEstadio INT IDENTITY, 
	Nome VARCHAR(100) NOT NULL,
	Cidade VARCHAR(80) NOT NULL, 
	Capacidade INT NOT NULL,

	PRIMARY KEY (idEstadio),
	CHECK(Capacidade > 0)
)

INSERT INTO Estadios VALUES
('Al Thumama', 'Doha', 40000),
('Khalifa International', 'Doha', 40000),
('Ahmad bin Ali', 'Al Rayyan', 40000),
('Al Bayt', 'Al Khor', 60000),
('Lusail', 'Lusail', 80000),
('Al Janoub', 'Al Wakrah', 40000),
('Education City', 'Al Rayyan', 40000)

CREATE TABLE Selecoes(
	idSelecao INT IDENTITY, 
	Pais VARCHAR(40) NOT NULL, 
	GolsMarcados INT NOT NULL, 
	GolsSofridos INT NOT NULL,
	Pontos INT NOT NULL,

	PRIMARY KEY (idSelecao),
	CHECK (GolsMarcados >= 0),
	CHECK (GolsSofridos >= 0),
	CHECK (Pontos >= 0)
)

INSERT INTO Selecoes VALUES
('Catar', 1, 7, 0),
('Fran�a', 6, 3, 6),
('Marrocos', 4, 1, 7),
('Brasil', 3, 1, 6),
('Portugal', 6, 4, 6),
('Holanda', 5, 1, 7),
('Argentina', 5, 2, 6),
('Cro�cia', 4, 1, 5),
('Pol�nia', 2, 2, 4),
('Alemanha', 6, 5, 4)

CREATE TABLE Partidas(
	idPartida INT IDENTITY,
	Data DATE NOT NULL,
	Hora TIME NOT NULL, 
	PublicoEstimado INT NOT NULL,
	Time1 INT NOT NULL,
	Placar1 INT NOT NULL,
	Time2 INT NOT NULL,
	Placar2 INT NOT NULL,
	Resultado VARCHAR(50) DEFAULT NULL,
	Local INT NOT NULL,

	PRIMARY KEY (idPartida),
	FOREIGN KEY (Time1) REFERENCES Selecoes,
	FOREIGN KEY (Time2) REFERENCES Selecoes,
	FOREIGN KEY (Local) REFERENCES Estadios,
	CHECK (PublicoEstimado > 0),
	CHECK (Placar1 >= 0),
	CHECK (Placar2 >= 0)
)

INSERT INTO Partidas VALUES 
('25/11/2022', '16:00:00', 30000, 2, 2, 4, 1, 'Fran�a', 2),
('27/11/2022', '13:00:00', 40000, 3, 0, 1, 0, 'Empate', 1),
('30/11/2022', '07:00:00', 55000, 4, 1, 5, 2, 'Portugal', 4),
('02/12/2022', '11:00:00', 68000, 7, 0, 10, 3, null, 5),
('05/12/2022', '16:00:00', 38000, 9, 2, 6, 1, null, 3)

SELECT * FROM Partidas
SELECT * FROM Selecoes
SELECT * FROM Estadios


/*2) Crie uma fun��o chamada quantEmpates que receba por par�metro o nome de um
est�dio e retorne a quantidade de partidas realizadas nele que resultaram em empate.
(Ex: Retornar quantos empates ocorreram no est�dio Al Bayt)*/

CREATE OR ALTER FUNCTION quantEmpates (@NomeEstadio VARCHAR (50)) 
RETURNS INT AS
	BEGIN 
	DECLARE @result INT
	SET @result = (SELECT COUNT(P.Resultado) 
	FROM Partidas AS P
	INNER JOIN Estadios E ON P.Local = E.idEstadio
	WHERE E.Nome = @NomeEstadio AND P.Resultado = 'Empate')

	RETURN @result 
	END
GO

SELECT dbo.quantEmpates ('Al Thumama') as Resultado

/*3) Crie um procedimento chamado excluiEstadios que receba por par�metro o nome de
uma cidade e exclua todos os est�dios localizados nela. (Ex: Exluir todos os est�dios da
cidade Al Rayyan) (Dica: Pode ser necess�rio excluir outros dados)*/

CREATE OR ALTER PROCEDURE excluiEstadios(@nomeCidade VARCHAR (50))
AS 

BEGIN

	DELETE Partidas WHERE Local IN (SELECT idEstadio FROM Estadios WHERE Cidade = @nomeCidade)
	DELETE Estadios WHERE idEstadio IN (SELECT idEstadio FROM Estadios WHERE Cidade = @nomeCidade)
	
END

EXEC excluiEstadios 'Al Khor'



/*4) Considerando as regras abaixo, crie um gatilho chamado verificaPartida que analise se
o registro de uma nova partida pode ser mantido ou n�o. Caso possa, dever� ser feita a
atualiza��o do atributo Resultado na tabela. Caso contr�rio, a opera��o dever� ser
desfeita e uma mensagem explicando o problema encontrado dever� ser exibida.

� Regra de Neg�cio: Uma partida n�o pode ocorrer em um est�dio
com capacidade inferior ao p�blico estimado.

� Regra de Neg�cio: Sempre que uma partida � cadastrada, � preciso
determinar e registrar seu resultado. A sele��o vencedora ser�
aquela com maior placar na partida, e o nome do pa�s
correspondente dever� ser registrado (Ex: Portugal, Brasil, etc).
Caso as duas sele��es tenham o mesmo placar, o termo 'Empate'
dever� ser registrado no campo Resultado.*/

CREATE OR ALTER TRIGGER verificaPartida ON Partidas
FOR INSERT AS

BEGIN 
	DECLARE 
	@IDPartidasCadastradas INT,
	@IDEstadioPartida INT,
	@PublicoEstimadoPartida INT,
	@CapacidadeEstadioPartida INT,
	@PlacarTime1 INT,
	@PlacarTime2 INT,
	@IDTime1 INT,
	@IDTime2 INT,
	@NomeTime1 VARCHAR (30),
	@NomeTime2 VARCHAR (30)

	SET @IDPartidasCadastradas = (SELECT idPartida FROM inserted)
	SET @IDEstadioPartida = (SELECT Local FROM inserted)
	SET @PublicoEstimadoPartida = (SELECT PublicoEstimado FROM inserted)
	SET @CapacidadeEstadioPartida = (SELECT Capacidade FROM Estadios WHERE idEstadio = @IDEstadioPartida)
	SET @PlacarTime1 = (SELECT Placar1 FROM inserted)
	SET @PlacarTime2 = (SELECT Placar2 FROM inserted)
	SET @IDTime1 = (SELECT Time1 FROM inserted)
	SET @IDTime2 = (SELECT Time2 FROM inserted)
	
	SET @NomeTime1 = (SELECT Pais FROM Selecoes, Partidas
					  WHERE Selecoes.idSelecao = @IDTime1 AND Partidas.idPartida = @IDPartidasCadastradas)
	SET @NomeTime2 = (SELECT Pais FROM Selecoes, Partidas
					  WHERE Selecoes.idSelecao = @IDTime2 AND Partidas.idPartida = @IDPartidasCadastradas)
	
	IF(@CapacidadeEstadioPartida < @PublicoEstimadoPartida)
		BEGIN
			ROLLBACK
			PRINT 'O ESTADIO NAO POSSUI LUGARES SUFICIENTES'

		END
	ELSE 
		BEGIN
			 
			 IF(@PlacarTime1 > @PlacarTime2)
				BEGIN
				UPDATE Partidas
				SET Resultado = @NomeTime1 WHERE Partidas.idPartida = @IDPartidasCadastradas
				END

			IF(@PlacarTime2 > @PlacarTime1)
				BEGIN
				UPDATE Partidas
				SET Resultado = @NomeTime2 WHERE Partidas.idPartida = @IDPartidasCadastradas
				END

			IF(@PlacarTime1 = @PlacarTime2)
				BEGIN
				UPDATE Partidas
				SET Resultado = 'Empate' WHERE Partidas.idPartida = @IDPartidasCadastradas
				END

		END

END

INSERT INTO Partidas VALUES
('10/12/2022', '14:00:00', 800, 6, 4, 9, 1, 'Holanda', 6)



/*5) Considerando as regras abaixo, crie um gatilho chamado atualizaSelecoes que atualize
os dados de cada sele��o participante de cada partida cadastrada.

� Regra de Neg�cio: Sempre que vence uma partida, a sele��o ganha
3 pontos. Quando perde uma partida, a sele��o perde 1 ponto,
mas apenas se tiver pontua��o acima de zero. Em caso de empate,
cada sele��o participante da partida ganha 1 ponto.*/

CREATE OR ALTER TRIGGER atualizaSelecoes ON Partidas
FOR INSERT AS
BEGIN

	DECLARE 
	@IDPartida INT,
	@PlacarTime1 INT,
	@PlacarTime2 INT,
	@IDTime1 INT,
	@IDTime2 INT

	SET @IDPartida = (SELECT idPartida FROM inserted) 
	SET @PlacarTime1 = (SELECT Placar1 FROM inserted)
	SET @PlacarTime2 = (SELECT Placar2 FROM inserted)
	SET @IDTime1 = (SELECT Time1 FROM inserted)
	SET @IDTime2 = (SELECT Time2 FROM inserted)

	IF(@PlacarTime1 > @PlacarTime2)
	BEGIN
		UPDATE Selecoes
		SET Pontos = Pontos + 3 WHERE @IDTime1 = Selecoes.idSelecao
		
		UPDATE Selecoes
		SET Pontos = Pontos - 1 WHERE @IDTime2 = Selecoes.idSelecao AND Pontos > 0

		UPDATE Selecoes
		SET GolsMarcados = GolsMarcados + @PlacarTime1 WHERE @IDTime1 = Selecoes.idSelecao 

		UPDATE Selecoes
		SET GolsMarcados = GolsMarcados + @PlacarTime2 WHERE @IDTime2 = Selecoes.idSelecao 

		UPDATE Selecoes
		SET GolsSofridos = GolsSofridos + @PlacarTime2 WHERE @IDTime1 = Selecoes.idSelecao 

		UPDATE Selecoes
		SET GolsSofridos = GolsSofridos + @PlacarTime1 WHERE @IDTime2 = Selecoes.idSelecao 
	END

	IF(@PlacarTime2 > @PlacarTime1)
	BEGIN
		UPDATE Selecoes
		SET Pontos = Pontos + 3 WHERE @IDTime2 = Selecoes.idSelecao
		
		UPDATE Selecoes
		SET Pontos = Pontos - 1 WHERE @IDTime1 = Selecoes.idSelecao AND Pontos > 0

		UPDATE Selecoes
		SET GolsMarcados = GolsMarcados + @PlacarTime2 WHERE @IDTime2 = Selecoes.idSelecao 

		UPDATE Selecoes
		SET GolsMarcados = GolsMarcados + @PlacarTime1 WHERE @IDTime1 = Selecoes.idSelecao 

		UPDATE Selecoes
		SET GolsSofridos = GolsSofridos + @PlacarTime2 WHERE @IDTime1 = Selecoes.idSelecao 

		UPDATE Selecoes
		SET GolsSofridos = GolsSofridos + @PlacarTime1 WHERE @IDTime2 = Selecoes.idSelecao 

	END

	IF(@PlacarTime1 = @PlacarTime2)
	BEGIN
		UPDATE Selecoes
		SET Pontos = Pontos + 1 WHERE @IDTime1 = Selecoes.idSelecao

		UPDATE Selecoes
		SET Pontos = Pontos + 1 WHERE @IDTime2 = Selecoes.idSelecao

		UPDATE Selecoes
		SET GolsMarcados = GolsMarcados + @PlacarTime2 WHERE @IDTime2 = Selecoes.idSelecao 

		UPDATE Selecoes
		SET GolsMarcados = GolsMarcados + @PlacarTime1 WHERE @IDTime1 = Selecoes.idSelecao 

		UPDATE Selecoes
		SET GolsSofridos = GolsSofridos + @PlacarTime2 WHERE @IDTime1 = Selecoes.idSelecao 

		UPDATE Selecoes
		SET GolsSofridos = GolsSofridos + @PlacarTime1 WHERE @IDTime2 = Selecoes.idSelecao 
	END
END


INSERT INTO Partidas VALUES
('19/02/2020', '18:00:00', 30000, 1, 100, 9, 100, 'Empate', 6)

SELECT * FROM Partidas
SELECT * FROM Selecoes
SELECT * FROM Estadios